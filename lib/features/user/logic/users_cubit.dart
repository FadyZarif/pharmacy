import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import 'package:pharmacy/features/user/logic/users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit() : super(UsersInitial()) {
    listenToUsers();
  }

  List<UserModel> allUsers = [];
  StreamSubscription? _usersSubscription;

  /// Listen to real-time updates for users
  void listenToUsers() {
    _usersSubscription?.cancel();
    emit(FetchUsersLoading());

    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .where('branches', arrayContains: {
          'id': currentUser.currentBranch.id,
          'name': currentUser.currentBranch.name,
        })
    .where('role', isNotEqualTo: Role.admin.name)
        .snapshots()
        .listen(
          (snapshot) {
            allUsers = snapshot.docs
                .map((doc) => UserModel.fromJson(doc.data()))
                .toList();
            emit(FetchUsersSuccess(allUsers));
          },
          onError: (error) {
            emit(FetchUsersError('Failed to fetch users: $error'));
          },
        );
  }

  /// Filter users by search query and role
  List<UserModel> filterUsers({
    required String searchQuery,
    Role? selectedRole,
    bool? isActive,
  }) {
    return allUsers.where((user) {
      // Search filter
      final matchesSearch = searchQuery.isEmpty ||
          user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user.phone.toLowerCase().contains(searchQuery.toLowerCase());

      // Role filter
      final matchesRole = selectedRole == null || user.role == selectedRole;

      // Active status filter
      final matchesActive = isActive == null || user.isActive == isActive;

      return matchesSearch && matchesRole && matchesActive;
    }).toList();
  }

  /// Upload image to Firebase Storage
  Future<String> uploadUserImage(Uint8List imageBytes, String userId, String fileName) async {
    try {
      final extension = fileName.split('.').last.toLowerCase();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile')
          .child('$userId.$extension');

      String contentType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        default:
          contentType = 'image/jpeg';
      }

      final uploadTask = await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: contentType),
      );
      final imageUrl = await uploadTask.ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Add new user
  Future<void> addUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? printCode,
    required int shiftHours,
    required int vocationBalanceMinutes,
    required Role role,
    required bool isActive,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    emit(AddUserLoading());

    User? createdUser;
    String? photoUrl;

    try {
      // Step 1: Create Firebase Auth user
      // حفظ المستخدم الحالي قبل إنشاء مستخدم جديد

      // Step 1: Create Firebase Auth user في instance منفصل
      final secondaryApp = await Firebase.initializeApp(
        name: 'Secondary',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      createdUser = userCredential.user;
      final uid = createdUser!.uid;

      // Step 2: Upload image if provided (يجب أن تنجح قبل المتابعة)
      if (imageBytes != null && imageName != null) {
        try {
          photoUrl = await uploadUserImage(imageBytes, uid, imageName);
        } catch (uploadError) {
          // إذا فشل رفع الصورة، احذف المستخدم من Auth
          await createdUser.delete();
          await secondaryApp.delete(); // حذف الـ app المؤقت
          throw Exception('Failed to upload profile image: $uploadError');
        }
      }

      // Step 3: Create user document in Firestore
      // نستخدم currentUser.currentBranch مباشرة هنا قبل أي تغيير

      final userData = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        printCode: printCode?.trim(),
        branches: [currentUser.currentBranch], // استخدام نسخة محلية بدلاً من global
        vocationBalanceMinutes: vocationBalanceMinutes,
        overTimeHours: 0,
        shiftHours: shiftHours,
        role: role,
        photoUrl: photoUrl,
        isActive: isActive,
      );

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userData.toJson());
      } catch (firestoreError) {
        // إذا فشل Firestore، احذف المستخدم من Auth والصورة من Storage
        await createdUser.delete();

        if (photoUrl != null) {
          try {
            await FirebaseStorage.instance
                .ref()
                .child('profile')
                .child('$uid.jpg')
                .delete();
          } catch (_) {
            // تجاهل خطأ حذف الصورة
          }
        }
        await secondaryApp.delete();
        throw Exception('Failed to create user document: $firestoreError');
      }

      // Step 4: Sign out من الـ secondary auth وحذف الـ app
      await secondaryAuth.signOut();
      await secondaryApp.delete();

      emit(AddUserSuccess());
    } catch (e) {
      // Rollback: إذا حصل أي خطأ لم يتم التعامل معه
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // تجاهل خطأ الحذف
        }
      }

      emit(AddUserError('Failed to add user: $e'));
    }
  }

  /// Update existing user
  Future<void> updateUser({
    required String uid,
    required String name,
    required String phone,
    String? printCode,
    required int shiftHours,
    required int vocationBalanceMinutes, // Vacation balance in minutes
    required Role role,
    required bool isActive,
    bool? hasRequestsPermission,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    emit(UpdateUserLoading());

    String? newPhotoUrl;
    String? oldPhotoUrl;

    try {
      // Step 1: Get old photo URL to delete later if needed
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        oldPhotoUrl = userData?['photoUrl'];
      }

      // Step 2: Upload new image if provided
      if (imageBytes != null && imageName != null) {
        newPhotoUrl = await uploadUserImage(imageBytes, uid, imageName);
      }

      // Step 3: Update user document
      final updatedData = {
        'name': name.trim(),
        'phone': phone.trim(),
        'printCode': printCode?.trim(),
        'shiftHours': shiftHours,
        'vocationBalanceMinutes': vocationBalanceMinutes,
        'role': role.name,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add hasRequestsPermission only if provided (for subManagers)
      if (hasRequestsPermission != null) {
        updatedData['hasRequestsPermission'] = hasRequestsPermission;
      }

      if (newPhotoUrl != null) {
        updatedData['photoUrl'] = newPhotoUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updatedData);

      // Step 4: Delete old photo AFTER successful update
      // حذف الصورة القديمة بعد نجاح التحديث فقط
      if (imageBytes != null && oldPhotoUrl != null && oldPhotoUrl.isNotEmpty) {
        try {
          // Extract filename from old URL to delete it
          final oldFileName = Uri.parse(oldPhotoUrl).pathSegments.last.split('?').first;
          await FirebaseStorage.instance
              .ref()
              .child('profile')
              .child(oldFileName)
              .delete();
        } catch (_) {
          // تجاهل خطأ حذف الصورة القديمة
        }
      }

      emit(UpdateUserSuccess());
    } catch (e) {
      // Rollback: إذا تم رفع صورة جديدة لكن فشل التحديث
      if (newPhotoUrl != null) {
        try {
          await FirebaseStorage.instance
              .ref()
              .child('profile')
              .child('$uid.jpg')
              .delete();
        } catch (_) {
          // تجاهل خطأ الحذف
        }
      }

      emit(UpdateUserError('Failed to update user: $e'));
    }
  }

  /// Delete user
  Future<void> deleteUser(String uid) async {
    emit(DeleteUserLoading());

    try {
      // Step 1: Get user data to check photo
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      String? photoUrl;
      if (userDoc.exists) {
        final userData = userDoc.data();
        photoUrl = userData?['photoUrl'];
      }

      // Step 2: Delete user document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .delete();

      // Step 3: Delete profile photo if exists
      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance
              .ref()
              .child('profile')
              .child('$uid.jpg')
              .delete();
        } catch (_) {
          // تجاهل خطأ حذف الصورة
        }
      }

      // Step 4: Delete from Firebase Auth
      // ملحوظة: لا يمكن حذف مستخدم آخر من Auth مباشرة
      // يحتاج Cloud Function أو المستخدم نفسه يحذف حسابه



      emit(DeleteUserSuccess());
    } catch (e) {
      emit(DeleteUserError('Failed to delete user: $e'));
    }
  }

  @override
  Future<void> close() {
    _usersSubscription?.cancel();
    return super.close();
  }
}

