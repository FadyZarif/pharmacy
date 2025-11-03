
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/branch/data/branch_model.dart';
import 'package:pharmacy/features/login/data/models/user_model.dart';
import 'package:pharmacy/features/request/data/models/request_model.dart';

import 'request_state.dart';


class RequestCubit extends Cubit<RequestState> {
  RequestCubit() : super(RequestInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  addRequest({required RequestModel request,required DocumentReference docRef,PlatformFile? file}) async {
    emit(AddRequestLoading());
    try {
      // Simulate adding request logic
      // On success:
      if(file != null){

        print('uploading file: ${file.name}');
        // افترض أن لديك دالة لرفع الملف وإرجاع الرابط
        String fileUrl = await uploadFileAndGetUrl(file);
        request.details['prescription'] = fileUrl;
      }
      docRef.set(request.toJson());


      emit(AddRequestSuccess());
    } catch (e) {
      emit(AddRequestFailure(error: e.toString()));
    }
  }
  Future<String> uploadFileAndGetUrl(PlatformFile pickedFile) async {

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final ref = FirebaseStorage.instance.ref().child('sick/$fileName');

      // ابدأ الرفع (ويب: bytes | موبايل/ديسكتوب: ملف من المسار)
        final file = File(pickedFile.path!);
     final snapshot = await ref.putFile(
          file,
          SettableMetadata(contentType: pickedFile.xFile.mimeType),
        );

      // انتظار الاكتمال
      final url = await snapshot.ref.getDownloadURL();

      return url;
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }
  updateRequest({required RequestModel request,PlatformFile? file}) async {
    emit(AddRequestLoading());
    try {
      // Simulate adding request logic
      // On success:
      if(file != null){

        // افترض أن لديك دالة لرفع الملف وإرجاع الرابط
        String fileUrl = await uploadFileAndGetUrl(file);
        request.details['prescription'] = fileUrl;
      }
      _db
          .collection('requests')
          .doc(request.id,)
          .update(
          {...request.toJson(), 'updatedAt': FieldValue.serverTimestamp()},
      );
      emit(AddRequestSuccess());
    } catch (e) {
      emit(AddRequestFailure(error: e.toString()));
    }
  }
  deleteRequest(String requestId) async {
    emit(DeleteRequestLoading());
    try {
      // Simulate deleting request logic
      // On success:
      await _db.collection('requests').doc(requestId).delete();
      emit(DeleteRequestSuccess());
    } catch (e) {
      emit(DeleteRequestFailure(error: e.toString()));
    }
  }


  ///Fetch Requests for month
  List<RequestModel> requests = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _requestsSub;

  Query<Map<String, dynamic>> getRequestsQuery() {
    final now = DateTime.now(); // عرّفها هنا
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1); // يتعامل تلقائيًا مع ديسمبر

    return _db
        .collection('requests')
        .where('employeeId', isEqualTo: currentUser.uid)
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .where('createdAt', isLessThan: endOfMonth)
    // لازم يكون أول orderBy على نفس حقل الـ range
        .orderBy('createdAt', descending: true);
  }

  void fetchRequests() {
    emit(FetchRequestsLoading());

    _requestsSub?.cancel();

    _requestsSub = getRequestsQuery().snapshots().listen(
          (snapshot) {
        for (final change in snapshot.docChanges) {
          final doc = change.doc;
          final id = doc.id;

          // ابنِ الموديل من الدوك
          final model = RequestModel.fromJson(doc.data()!);

          switch (change.type) {
            case DocumentChangeType.added:
            // أضف العنصر في الموضع الصحيح حسب newIndex
              final i = change.newIndex;
              if (i >= 0 && i <= requests.length) {
                requests.insert(i, model);
              } else {
                // احتياط لو المؤشر غير متوقع
                requests.add(model);
              }
              break;

            case DocumentChangeType.modified:
            // لو ترتيب العنصر اتغير (مثلاً اتغير createdAt)، حركه
              if (change.oldIndex != change.newIndex) {
                // شِل القديم من مكانه القديم
                if (change.oldIndex >= 0 && change.oldIndex < requests.length) {
                  requests.removeAt(change.oldIndex);
                }
                // دخّل النسخة المُحدّثة في مكانها الجديد
                final i = change.newIndex;
                if (i >= 0 && i <= requests.length) {
                  requests.insert(i, model);
                } else {
                  requests.add(model);
                }
              } else {
                // نفس المكان: بس حدّث الداتا
                if (change.oldIndex >= 0 && change.oldIndex < requests.length) {
                  requests[change.oldIndex] = model;
                }
              }
              break;

            case DocumentChangeType.removed:
            // احذف من مكانه القديم
              if (change.oldIndex >= 0 && change.oldIndex < requests.length) {
                requests.removeAt(change.oldIndex);
              } else {
                // احتياط: لو المؤشر مش مظبوط، احذف بالـ id
                final idx = requests.indexWhere((r) => r.id == id);
                if (idx != -1) requests.removeAt(idx);
              }
              break;
          }
        }

        emit(FetchRequestsSuccess());
      },
      onError: (e) => emit(FetchRequestsFailure(error: e.toString())),
    );
  }

  int get pendingRequestsCount =>
     requests.where((r) => r.status == RequestStatus.pending).length;

  /// Shift Coverage
  Map<BranchModel, List<UserModel>> branchesWithEmployees = {};
  BranchModel? selectedBranch;
  UserModel? selectedEmployee;

  Future<void> preloadAllBranchesWithEmployees(String? peerBranchId , String? peerEmployeeId) async {
    if (branchesWithEmployees.isNotEmpty) {
      if(peerBranchId != null && peerEmployeeId != null){

        selectedBranch = branchesWithEmployees.keys.firstWhere((branch)=>branch.id==peerBranchId);
        selectedEmployee = branchesWithEmployees[selectedBranch]!.firstWhere((employee)=>employee.uid == peerEmployeeId);
      }
      emit(FetchBranchesWithEmployeesSuccess());
      return;
    }
    emit(FetchBranchesWithEmployeesLoading());

    try {
      // 1) هات كل الفروع الفعالة
      final branchesSnap = await _db
          .collection('branches')
          .get();

      final branches = branchesSnap.docs
          .map((d) => BranchModel.fromJson(d.data()))
          .toList();

      // بنجيب كل الموظفين النشيطين مرة واحدة
      final snapshot = await _db
          .collection('users')
          .where('role',isEqualTo: Role.staff.name)
          .get();

      // بنحوّلهم لـ UserModel
      final users = snapshot.docs.map((doc) {
        return UserModel.fromJson(doc.data());
      }).where((u) => u.uid != currentUser.uid).toList();

      // نفضي الماب الأول
      branchesWithEmployees.clear();

      // 1) خريطة سريعة من branchId -> BranchModel
      final branchesById = { for (final b in branches) b.id : b };

      // 2) جمِّع الـ users حسب branchId (O(n))
      final Map<String, List<UserModel>> usersByBranchId = {};
      for (final u in users) {
        final bid = u.branchId; // اعملها nullable-safe لو لزم
        (usersByBranchId[bid] ??= <UserModel>[]).add(u);
      }

      // 3) حوّلها لـ Map<BranchModel, List<UserModel>>
       branchesWithEmployees = {
        for (final entry in usersByBranchId.entries)
          if (branchesById[entry.key] != null) branchesById[entry.key]!: entry.value
      };

      // (اختياري) لو عايز كل الفروع حتى الفاضية:
      for (final b in branches) {
        branchesWithEmployees.putIfAbsent(b, () => <UserModel>[]);
      }


      /*// نوزّع كل موظف على فرعه
      for (var user in users) {
        BranchModel branchModel = branches.firstWhere((branch)=>branch.id==user.branchId);
        branchesWithEmployees.putIfAbsent(branchModel, () => []);
        branchesWithEmployees[branchModel]!.add(user);
      }*/
      if(peerBranchId != null && peerEmployeeId != null){
        selectedBranch = branchesWithEmployees.keys.firstWhere((branch)=>branch.id==peerBranchId);
        selectedEmployee = branchesWithEmployees[selectedBranch]!.firstWhere((employee)=>employee.uid == peerEmployeeId);
      }

      emit(FetchBranchesWithEmployeesSuccess());
    } catch (e) {
      emit(FetchBranchesWithEmployeesFailure(error: 'فشل تحميل الموظفين: $e'));
    }
  }

  void setBranch(BranchModel branch) {
    selectedBranch = branch;
    selectedEmployee =null;
    emit(FetchBranchesWithEmployeesSuccess());

    // emit();
    //
    // // استدعاء الدالة اللي بتحط في الكاش
    // _fetchEmployeesForBranch(b.id);
  }





// مهم: اقفل الاشتراك لما الـ Cubit يتقفل
  @override
  Future<void> close() {
    _requestsSub?.cancel();
    return super.close();
  }
}
