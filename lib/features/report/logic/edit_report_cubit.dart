import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/edit_report_state.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';

import '../../../core/enums/notification_type.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/di/dependency_injection.dart';

class EditReportCubit extends Cubit<EditReportState> {
  EditReportCubit() : super(EditReportInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// تحديث الريبورت
  /// البنية: daily_reports/{date}/branches/{branchId}/shifts/{shiftType}
  Future<void> updateReport(ShiftReportModel report, String date) async {
    emit(EditReportLoading());

    try {
      final reportData = report.toJson();
      reportData['updatedAt'] = FieldValue.serverTimestamp();

      // Update في المسار الصحيح
      await _db
          .collection('daily_reports')
          .doc(date)
          .collection('branches')
          .doc(report.branchId)
          .collection('shifts')
          .doc(report.shiftType.name)
          .update(reportData);

      // Send notification to subManagers, managers and admins
      await _sendShiftReportUpdatedNotification(report, date);

      emit(EditReportSuccess());
    } catch (e) {
      emit(EditReportError(message: e.toString()));
    }
  }

  /// Helper: Send notification when shift report is updated
  Future<void> _sendShiftReportUpdatedNotification(ShiftReportModel report, String date) async {
    try {
      final notificationService = getIt<NotificationService>();

      // Get subManagers, managers and admins for this branch
      final managerIds = await notificationService.getUserIdsByRoleAndBranches(
        roles: [Role.subManager.name, Role.manager.name, Role.admin.name],
        branchIds: [report.branchId],
      );

      if (managerIds.isEmpty) return;

      // Get shift type name in Arabic
      String shiftTypeName = report.shiftNameAr;

      await notificationService.sendNotificationToUsers(
        userIds: managerIds,
        title: 'تم تعديل تقرير شيفت - ${report.branchName}',
        body: 'تم تعديل تقرير شيفت $shiftTypeName بتاريخ $date',
        type: NotificationType.shiftReportUpdated,
        additionalData: {
          'branchId': report.branchId,
          'shiftType': report.shiftType.name,
          'date': date,
        },
      );
    } catch (e) {
      print('Error sending shift report update notification: $e');
    }
  }
}


