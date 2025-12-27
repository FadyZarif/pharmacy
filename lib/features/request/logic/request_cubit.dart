import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/enums/notification_type.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/services/notification_service.dart';
import 'package:pharmacy/features/branch/data/branch_model.dart';
import 'package:pharmacy/features/request/data/models/request_model.dart';
import 'package:pharmacy/features/request/data/services/coverage_shift_service.dart';

import '../../user/data/models/user_model.dart';
import 'request_state.dart';


class RequestCubit extends Cubit<RequestState> {
  RequestCubit() : super(RequestInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  addRequest({required RequestModel request,required DocumentReference docRef,PlatformFile? file}) async {
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
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final ref = FirebaseStorage.instance.ref().child('sick/$fileName');

      // Get bytes for upload (works on both web and mobile)
      Uint8List? bytes = pickedFile.bytes;

      // If bytes not available (mobile), read from path
      if (bytes == null && pickedFile.path != null && !kIsWeb) {
        final file = File(pickedFile.path!);
        bytes = await file.readAsBytes();
      }

      if (bytes == null) {
        throw Exception('File has no bytes or path');
      }

      // Upload using putData (works on both web and mobile)
      final snapshot = await ref.putData(
        bytes,
        SettableMetadata(contentType: pickedFile.xFile.mimeType),
      );

      // Get download URL
      final url = await snapshot.ref.getDownloadURL();

      return url;
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }

  updateRequest({required RequestModel request,PlatformFile? file}) async {
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
    // final now = DateTime.now(); // عرّفها هنا
    // final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    // final startOfMonth = DateTime(now.year, now.month, 1);
    // final endOfMonth = DateTime(now.year, now.month + 1, 1); // يتعامل تلقائيًا مع ديسمبر
    final thirtyDaysAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 30))
    );
    // نضيف يوم واحد للمستقبل عشان نلحق الـ requests اللي هتتضاف دلوقتي
    final tomorrow = Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 1))
    );

    return _db
        .collection('requests')
        .where('employeeId', isEqualTo: currentUser.uid)
        .where('createdAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
        .where('createdAt', isLessThan: tomorrow)
        .orderBy('createdAt', descending: true);
  }

  void fetchRequests() {
    emit(FetchRequestsLoading());

    _requestsSub?.cancel();
    requests.clear();
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

  /// Fetch Management Requests (for managers/admins)
  /// Management Requests (for managers/admins)
  List<RequestModel> managementRequests = [];
  StreamSubscription? _managementRequestsSub;
  DateTime selectedMonth = DateTime.now();
  RequestStatus selectedStatus = RequestStatus.pending;
  void fetchManagementRequests() {
    emit(FetchRequestsLoading());

    _managementRequestsSub?.cancel();

    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    Query query = _db
        .collection('requests')
        .where('status', isEqualTo: selectedStatus.name)
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .where('createdAt', isLessThan: endOfMonth)
        .where('employeeBranchId', isEqualTo: currentUser.currentBranch.id)
        .orderBy('createdAt', descending: true);

    // Filter by branch for managers
    // if (currentUser.role == Role.manager) {
    //   query = query.where('employeeBranchId', isEqualTo: currentUser.currentBranch.id);
    // }

    _managementRequestsSub = query.snapshots().listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          final doc = change.doc;
          final model = RequestModel.fromJson(doc.data() as Map<String, dynamic>);

          switch (change.type) {
            case DocumentChangeType.added:
              final i = change.newIndex;
              if (i >= 0 && i <= managementRequests.length) {
                managementRequests.insert(i, model);
              } else {
                managementRequests.add(model);
              }
              break;

            case DocumentChangeType.modified:
              if (change.oldIndex != change.newIndex) {
                if (change.oldIndex >= 0 && change.oldIndex < managementRequests.length) {
                  managementRequests.removeAt(change.oldIndex);
                }
                final i = change.newIndex;
                if (i >= 0 && i <= managementRequests.length) {
                  managementRequests.insert(i, model);
                } else {
                  managementRequests.add(model);
                }
              } else {
                if (change.oldIndex >= 0 && change.oldIndex < managementRequests.length) {
                  managementRequests[change.oldIndex] = model;
                }
              }
              break;

            case DocumentChangeType.removed:
              if (change.oldIndex >= 0 && change.oldIndex < managementRequests.length) {
                managementRequests.removeAt(change.oldIndex);
              } else {
                final idx = managementRequests.indexWhere((r) => r.id == doc.id);
                if (idx != -1) managementRequests.removeAt(idx);
              }
              break;
          }
        }

        emit(FetchRequestsSuccess());
      },
      onError: (e) => emit(FetchRequestsFailure(error: e.toString())),
    );
  }

  /// Change selected status filter
  void changeStatus(RequestStatus status) {
    if (selectedStatus == status) return;
    selectedStatus = status;
    managementRequests.clear();
    fetchManagementRequests();
  }

  /// Change selected month filter
  void changeMonth(DateTime month) {
    selectedMonth = DateTime(month.year, month.month, 1);
    managementRequests.clear();
    fetchManagementRequests();
  }

  /// Go to previous month
  void previousMonth() {
    final newMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    changeMonth(newMonth);
  }

  /// Go to next month
  void nextMonth() {
    final newMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    changeMonth(newMonth);
  }

  /// Reset to current month
  void resetToCurrentMonth() {
    changeMonth(DateTime.now());
  }

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
        final bid = u.currentBranch.id; // اعملها nullable-safe لو لزم
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
    } catch (e,s) {
      print(e);
      print(s);
      emit(FetchBranchesWithEmployeesFailure(error: 'فشل تحميل الموظفين: $e'));
    }
  }

  void setBranch(BranchModel branch) {
    selectedBranch = branch;
    selectedEmployee =null;
    emit(FetchBranchesWithEmployeesSuccess());
  }

  /// Check if employee has approved leave on specific date
  Future<bool> checkEmployeeHasLeaveOnDate(
    String employeeId,
    DateTime date,
  ) async {
    try {
      final snapshot = await _db
          .collection('requests')
          .where('employeeId', isEqualTo: employeeId)
          .where('status', isEqualTo: RequestStatus.approved.name)
          .where('type',
              whereIn: [RequestType.annualLeave.name, RequestType.sickLeave.name])
          .get();

      for (final doc in snapshot.docs) {
        final request = RequestModel.fromJson(doc.data());

        DateTime leaveStart;
        DateTime leaveEnd;

        if (request.type == RequestType.annualLeave) {
          final details = AnnualLeaveDetails.fromJson(request.details);
          leaveStart = details.startDate;
          leaveEnd = details.endDate;
        } else {
          final details = SickLeaveDetails.fromJson(request.details);
          leaveStart = details.startDate;
          leaveEnd = details.endDate;
        }

        // Check if date falls within leave range
        if (date.isAfter(leaveStart.subtract(const Duration(days: 1))) &&
            date.isBefore(leaveEnd.add(const Duration(days: 1)))) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Validate and submit request
  Future<void> submitRequest({
    required RequestType requestType,
    required Map<String, dynamic> details,
    String? notes,
    PlatformFile? file,
    RequestModel? existingRequest,
  }) async {
    emit(AddRequestLoading());

    try {
      // Create or update request
      final request = RequestModel(
        employeeId: currentUser.uid,
        employeeName: currentUser.name,
        employeePhone: currentUser.phone,
        employeeBranchId: currentUser.currentBranch.id,
        employeeBranchName: currentUser.currentBranch.name,
        employeePhoto: currentUser.photoUrl,
        id: existingRequest?.id ?? _db.collection('requests').doc().id,
        type: requestType,
        status: existingRequest?.status ?? RequestStatus.pending,
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        details: details,
        createdAt: existingRequest?.createdAt,
      );

      if (existingRequest == null) {
        // Add new request
        final docRef = _db.collection('requests').doc(request.id);
        await addRequest(
          request: request,
          docRef: docRef,
          file: file,
        );

        // Send notification to managers/admins about new request
        await _sendNewRequestNotification(request);
      } else {
        // Update existing request
        await updateRequest(
          request: request,
          file: file,
        );
      }
    } catch (e) {
      emit(AddRequestFailure(error: e.toString()));
    }
  }

  /// Approve Request (Manager/Admin only)
  Future<void> approveRequest(RequestModel request) async {
    try {
      emit(AddRequestLoading());

      // Get employee data
      final employeeDoc = await _db.collection('users').doc(request.employeeId).get();
      final employee = UserModel.fromJson(employeeDoc.data()!);

      // Calculate hours to add/subtract based on request type
      int vocationHoursChange = 0;
      int overTimeHoursChange = 0;

      switch (request.type) {
        case RequestType.annualLeave:
          final details = AnnualLeaveDetails.fromJson(request.details);
          final days = details.endDate.difference(details.startDate).inDays + 1;
          final requiredHours = days * employee.shiftHours;

          // Check if employee has enough vacation balance
          if (employee.vocationBalanceHours < requiredHours) {
            emit(AddRequestFailure(
              error: 'Employee does not have enough vacation balance. Required: $requiredHours hours, Available: ${employee.vocationBalanceHours} hours'
            ));
            return;
          }

          vocationHoursChange = -requiredHours; // Negative to subtract from balance
          break;

        case RequestType.sickLeave:
          final details = SickLeaveDetails.fromJson(request.details);
          final days = details.endDate.difference(details.startDate).inDays + 1;
          final requiredHours = days * employee.shiftHours;

          // Check if employee has enough vacation balance
          if (employee.vocationBalanceHours < requiredHours) {
            emit(AddRequestFailure(
              error: 'Employee does not have enough vacation balance. Required: $requiredHours hours, Available: ${employee.vocationBalanceHours} hours'
            ));
            return;
          }

          vocationHoursChange = -requiredHours; // Negative to subtract from balance
          break;

        case RequestType.permission:
          final details = PermissionDetails.fromJson(request.details);

          // Check if employee has enough vacation balance
          if (employee.vocationBalanceHours < details.hours) {
            emit(AddRequestFailure(
              error: 'Employee does not have enough vacation balance. Required: ${details.hours} hours, Available: ${employee.vocationBalanceHours} hours'
            ));
            return;
          }

          vocationHoursChange = -details.hours; // Negative to subtract from balance
          break;

        case RequestType.extraHours:
          final details = ExtraHoursDetails.fromJson(request.details);
          overTimeHoursChange = details.hours; // Positive to add overtime
          break;

        default:
          // No hours change for other types
          break;
      }

      // Update request status
      await _db.collection('requests').doc(request.id).update({
        'status': RequestStatus.approved.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'processedByName': currentUser.name,
      });

      // Update user hours if needed
      if (vocationHoursChange != 0 || overTimeHoursChange != 0) {
        final updates = <String, dynamic>{};

        if (vocationHoursChange != 0) {
          updates['vocationBalanceHours'] = employee.vocationBalanceHours + vocationHoursChange;
        }

        if (overTimeHoursChange != 0) {
          updates['overTimeHours'] = employee.overTimeHours + overTimeHoursChange;
        }

        await _db.collection('users').doc(request.employeeId).update(updates);
      }

      // If it's a coverage shift, create coverage shift record
      if (request.type == RequestType.coverageShift) {
        final details = CoverageShiftDetails.fromJson(request.details);

        final employee2Doc = await _db.collection('users').doc(details.peerEmployeeId).get();
        final employee2 = UserModel.fromJson(employee2Doc.data()!);

        // Create coverage shift
        final coverageShiftService = getIt<CoverageShiftService>();
        await coverageShiftService.createCoverageShift(
          requestId: request.id,
          date: details.date,
          employee1Id: request.employeeId,
          employee1OriginalBranch: Branch(id: request.employeeBranchId, name: request.employeeBranchName),
          employee1TempBranch: Branch(
            id: details.peerBranchId,
            name: details.peerBranchName,
          ),
          employee2Id: details.peerEmployeeId,
          employee2OriginalBranch: employee2.currentBranch,
          employee2TempBranch: Branch(
            id: request.employeeBranchId,
            name: request.employeeBranchName,
          ),
        );
      }

      // Send notification to employee
      await _sendRequestStatusNotification(request, RequestStatus.approved);

      emit(AddRequestSuccess());
    } catch (e) {
      print('Error approving request: $e');
      emit(AddRequestFailure(error: e.toString()));
      rethrow;
    }
  }

  /// Reject Request (Manager/Admin only)
  Future<void> rejectRequest(RequestModel request) async {
    try {
      emit(AddRequestLoading());

      // If request was previously approved, reverse the hours changes
      if (request.status == RequestStatus.approved) {
        // Get employee data
        final employeeDoc = await _db.collection('users').doc(request.employeeId).get();
        final employee = UserModel.fromJson(employeeDoc.data()!);

        // Calculate hours to reverse based on request type
        int vocationHoursChange = 0;
        int overTimeHoursChange = 0;

        switch (request.type) {
          case RequestType.annualLeave:
            final details = AnnualLeaveDetails.fromJson(request.details);
            final days = details.endDate.difference(details.startDate).inDays + 1;
            vocationHoursChange = (days * employee.shiftHours); // Positive to restore balance
            break;

          case RequestType.sickLeave:
            final details = SickLeaveDetails.fromJson(request.details);
            final days = details.endDate.difference(details.startDate).inDays + 1;
            vocationHoursChange = (days * employee.shiftHours); // Positive to restore balance
            break;

          case RequestType.permission:
            final details = PermissionDetails.fromJson(request.details);
            vocationHoursChange = details.hours; // Positive to restore balance
            break;

          case RequestType.extraHours:
            final details = ExtraHoursDetails.fromJson(request.details);
            overTimeHoursChange = -details.hours; // Negative to subtract overtime
            break;

          default:
            // No hours change for other types
            break;
        }

        // Update user hours if needed
        if (vocationHoursChange != 0 || overTimeHoursChange != 0) {
          final updates = <String, dynamic>{};

          if (vocationHoursChange != 0) {
            updates['vocationBalanceHours'] = employee.vocationBalanceHours + vocationHoursChange;
          }

          if (overTimeHoursChange != 0) {
            updates['overTimeHours'] = employee.overTimeHours + overTimeHoursChange;
          }

          await _db.collection('users').doc(request.employeeId).update(updates);
        }
      }

      // Update request status
      await _db.collection('requests').doc(request.id).update({
        'status': RequestStatus.rejected.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'processedByName': currentUser.name,
      });

      // If it's a coverage shift that was previously approved, delete coverage shift record
      if (request.type == RequestType.coverageShift && request.status == RequestStatus.approved) {
        final coverageShiftService = getIt<CoverageShiftService>();
        await coverageShiftService.deleteCoverageShift(request.id);
      }

      // Send notification to employee
      await _sendRequestStatusNotification(request, RequestStatus.rejected);

      emit(AddRequestSuccess());
    } catch (e) {
      print('Error rejecting request: $e');
      emit(AddRequestFailure(error: e.toString()));
      rethrow;
    }
  }

  /// Helper: Send notification to managers/admins when new request is created
  Future<void> _sendNewRequestNotification(RequestModel request) async {
    try {
      final notificationService = getIt<NotificationService>();

      // Get managers and admins for this branch
      final managerIds = await notificationService.getUserIdsByRoleAndBranches(
        roles: [Role.admin.name, Role.manager.name],
        branchIds: [request.employeeBranchId],
      );

      if (managerIds.isEmpty) return;

      // Get Arabic name for request type and notification type
      String requestTypeAr = request.type.arName;
      NotificationType notificationType = _getNewRequestNotificationType(request.type);

      await notificationService.sendNotificationToUsers(
        userIds: managerIds,
        title: 'طلب جديد - فرع ${request.employeeBranchName}',
        body: '${request.employeeName} - $requestTypeAr',
        type: notificationType,
        additionalData: {
          'requestId': request.id,
          'requestType': request.type.name,
          'branchId': request.employeeBranchId,
        },
      );
    } catch (e) {
      print('Error sending new request notification: $e');
    }
  }

  /// Helper: Send notification when request status changes (approved/rejected)
  Future<void> _sendRequestStatusNotification(RequestModel request, RequestStatus newStatus) async {
    try {
      final notificationService = getIt<NotificationService>();

      // Get Arabic name for request type
      String requestTypeAr = request.type.arName;

      // Determine status text and notification type
      String statusText = newStatus.arName;
      NotificationType notificationType = _getRequestStatusNotificationType(request.type, newStatus);

      await notificationService.sendNotificationToUsers(
        userIds: [request.employeeId],
        title: '$statusText علي $requestTypeAr',
        body: '$statusText طلب $requestTypeAr الخاص بك',
        type: notificationType,
        additionalData: {
          'requestId': request.id,
          'requestType': request.type.name,
          'status': newStatus.name,
        },
      );
    } catch (e) {
      print('Error sending request status notification: $e');
    }
  }

  /// Helper: Get notification type for new request based on request type
  NotificationType _getNewRequestNotificationType(RequestType type) {
    switch (type) {
      case RequestType.annualLeave:
        return NotificationType.newAnnualLeaveRequest;
      case RequestType.sickLeave:
        return NotificationType.newSickLeaveRequest;
      case RequestType.permission:
        return NotificationType.newPermissionRequest;
      case RequestType.attend:
        return NotificationType.newAttendRequest;
      case RequestType.extraHours:
        return NotificationType.newExtraHoursRequest;
      case RequestType.coverageShift:
        return NotificationType.newCoverageShiftRequest;
    }
  }

  /// Helper: Get notification type for request status based on request type and status
  NotificationType _getRequestStatusNotificationType(RequestType type, RequestStatus status) {
    if (status == RequestStatus.approved) {
      switch (type) {
        case RequestType.annualLeave:
          return NotificationType.annualLeaveApproved;
        case RequestType.sickLeave:
          return NotificationType.sickLeaveApproved;
        case RequestType.permission:
          return NotificationType.permissionApproved;
        case RequestType.attend:
          return NotificationType.attendApproved;
        case RequestType.extraHours:
          return NotificationType.extraHoursApproved;
        case RequestType.coverageShift:
          return NotificationType.coverageShiftApproved;
      }
    } else {
      switch (type) {
        case RequestType.annualLeave:
          return NotificationType.annualLeaveRejected;
        case RequestType.sickLeave:
          return NotificationType.sickLeaveRejected;
        case RequestType.permission:
          return NotificationType.permissionRejected;
        case RequestType.attend:
          return NotificationType.attendRejected;
        case RequestType.extraHours:
          return NotificationType.extraHoursRejected;
        case RequestType.coverageShift:
          return NotificationType.coverageShiftRejected;
      }
    }
  }

// مهم: اقفل الاشتراك لما الـ Cubit يتقفل
  @override
  Future<void> close() {
    _requestsSub?.cancel();
    _managementRequestsSub?.cancel();
    return super.close();
  }
}
