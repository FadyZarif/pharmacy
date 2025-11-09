import 'dart:async';
import 'dart:io';
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
  }) {
    return allUsers.where((user) {
      // Search filter
      final matchesSearch = searchQuery.isEmpty ||
          user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user.phone.toLowerCase().contains(searchQuery.toLowerCase());

      // Role filter
      final matchesRole = selectedRole == null || user.role == selectedRole;

      return matchesSearch && matchesRole;
    }).toList();
  }

  /// Upload image to Firebase Storage
  Future<String> uploadUserImage(File imageFile, String userId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile')
          .child('$userId.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
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
    required int vocationBalanceHours,
    required Role role,
    required bool isActive,
    File? imageFile,
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
      if (imageFile != null) {
        try {
          photoUrl = await uploadUserImage(imageFile, uid);
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
        vocationBalanceHours: vocationBalanceHours,
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
    required int vocationBalanceHours,
    required Role role,
    required bool isActive,
    File? imageFile,
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
      if (imageFile != null) {
        newPhotoUrl = await uploadUserImage(imageFile, uid);

        // Delete old photo if exists and new one uploaded successfully
        if (oldPhotoUrl != null && oldPhotoUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance
                .ref()
                .child('profile')
                .child('$uid.jpg')
                .delete();
          } catch (_) {
            // تجاهل خطأ حذف الصورة القديمة
          }
        }
      }

      // Step 3: Update user document
      final updatedData = {
        'name': name.trim(),
        'phone': phone.trim(),
        'printCode': printCode?.trim(),
        'vocationBalanceHours': vocationBalanceHours,
        'shiftHours': shiftHours,
        'role': role.name,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newPhotoUrl != null) {
        updatedData['photoUrl'] = newPhotoUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updatedData);

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

  @override
  Future<void> close() {
    _usersSubscription?.cancel();
    return super.close();
  }
}

