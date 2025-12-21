import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/report/data/helpers/report_firestore_helper.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/view_reports_state.dart';

import '../../../core/enums/notification_type.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/di/dependency_injection.dart';
import '../../user/data/models/user_model.dart';

class ViewReportsCubit extends Cubit<ViewReportsState> {
  ViewReportsCubit() : super(ViewReportsInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// جلب جميع الريبورتات ليوم محدد
  /// البنية: daily_reports/{date}/branches/{branchId}/shifts/{shiftType}
  Future<void> fetchDailyReports(String dateKey) async {
    emit(ViewReportsLoading());

    try {
      // جلب كل الشيفتات للفرع في هذا اليوم
      final shiftsSnapshot = await _db
          .collection('daily_reports')
          .doc(dateKey)
          .collection('branches')
          .doc(currentUser.currentBranch.id)
          .collection('shifts')
          .get();

      if (shiftsSnapshot.docs.isEmpty) {
        emit(ViewReportsEmpty());
        return;
      }

      final reports = <ShiftReportModel>[];

      for (var doc in shiftsSnapshot.docs) {
        final report = ShiftReportModel.fromJson(doc.data());
        reports.add(report);
      }

      // ترتيب حسب نوع الشيفت
      reports.sort((a, b) => a.shiftType.index.compareTo(b.shiftType.index));

      emit(ViewReportsLoaded(reports: reports));
    } catch (e) {
      emit(ViewReportsError(message: e.toString()));
    }
  }

  /// جلب إحصائيات الشهر كامل
  Future<void> fetchMonthlySummary(DateTime selectedDate) async {
    emit(MonthlySummaryLoading());

    try {
      // Get last day of selected month
      final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);

      double totalSales = 0.0;
      double totalExpenses = 0.0;
      double totalMedicinesExpenses = 0.0;
      double totalElectronicPaymentExpenses = 0.0;
      double vaultAmount = 0.0; // مجموع الأرباح غير المحصلة

      // Fetch reports for each day in the month
      for (int day = 1; day <= lastDay.day; day++) {
        final date = DateTime(selectedDate.year, selectedDate.month, day);
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        try {
          // جلب كل الشيفتات للفرع في هذا اليوم
          final shiftsSnapshot = await _db
              .collection('daily_reports')
              .doc(dateStr)
              .collection('branches')
              .doc(currentUser.currentBranch.id)
              .collection('shifts')
              .get();

          // Calculate daily totals
          double dailySales = 0.0;
          double dailyExpenses = 0.0;

          for (var doc in shiftsSnapshot.docs) {
            final report = ShiftReportModel.fromJson(doc.data());

            dailySales += report.drawerAmount;
            dailyExpenses += report.totalExpenses;
            totalSales += report.drawerAmount;
            totalExpenses += report.totalExpenses;

            totalMedicinesExpenses += report.medicineExpenses;
            totalElectronicPaymentExpenses += report.electronicWalletExpenses;
          }

          // Check if this day's profit is collected
          if (dailySales > 0 || dailyExpenses > 0) {
            final isCollected = await ReportFirestoreHelper.getCollectionStatus(
              date,
              currentUser.currentBranch.id,
            );

            // If not collected, add to vault
            if (!isCollected) {
              final dailyNetProfit = dailySales - dailyExpenses;
              vaultAmount += dailyNetProfit;
            }
          }
        } catch (e) {
          // Continue even if one day fails
          continue;
        }
      }

      final netProfit = totalSales - totalExpenses;

      emit(MonthlySummaryLoaded(
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
        totalMedicinesExpenses: totalMedicinesExpenses,
        totalElectronicPaymentExpenses: totalElectronicPaymentExpenses,
        vaultAmount: vaultAmount,
      ));
    } catch (e) {
      emit(MonthlySummaryError(message: e.toString()));
    }
  }

  /// تحديث حالة التحصيل لفرع في يوم معين
  Future<void> toggleCollectionStatus(String dateKey, bool currentStatus) async {
    emit(CollectionStatusLoading());

    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateKey);
      final newStatus = !currentStatus;

      await ReportFirestoreHelper.updateCollectionStatus(
        date,
        currentUser.currentBranch.id,
        newStatus,
      );

      // Send notification if profit was collected (newStatus = true)
      if (newStatus) {
        await _sendNetProfitCollectedNotification(dateKey);
      }

      emit(CollectionStatusUpdated(isCollected: newStatus));

      // Refresh reports to update UI
      await fetchDailyReports(dateKey);
    } catch (e) {
      emit(CollectionStatusError(message: e.toString()));
    }
  }

  /// جلب حالة التحصيل الحالية
  Future<void> fetchCollectionStatus(String dateKey) async {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateKey);
      final isCollected = await ReportFirestoreHelper.getCollectionStatus(
        date,
        currentUser.currentBranch.id,
      );

      emit(CollectionStatusLoaded(isCollected: isCollected));
    } catch (e) {
      emit(CollectionStatusError(message: e.toString()));
    }
  }

  /// Helper: Send notification when net profit is collected
  Future<void> _sendNetProfitCollectedNotification(String dateKey) async {
    try {
      final notificationService = getIt<NotificationService>();

      // Get managers and admins for this branch
      final managerIds = await notificationService.getUserIdsByRoleAndBranches(
        roles: [Role.admin.name, Role.manager.name],
        branchIds: [currentUser.currentBranch.id],
      );

      if (managerIds.isEmpty) return;

      // Calculate net profit for this day
      final shiftsSnapshot = await _db
          .collection('daily_reports')
          .doc(dateKey)
          .collection('branches')
          .doc(currentUser.currentBranch.id)
          .collection('shifts')
          .get();

      double totalSales = 0.0;
      double totalExpenses = 0.0;

      for (var doc in shiftsSnapshot.docs) {
        final report = ShiftReportModel.fromJson(doc.data());
        totalSales += report.drawerAmount;
        totalExpenses += report.totalExpenses;
      }

      final netProfit = totalSales - totalExpenses;

      await notificationService.sendNotificationToUsers(
        userIds: managerIds,
        title: 'تم تحصيل صافي الربح - ${currentUser.currentBranch.name}',
        body: 'تم تحصيل ${netProfit.toStringAsFixed(2)} جنيه من فرع ${currentUser.currentBranch.name} بتاريخ $dateKey',
        type: NotificationType.netProfitCollected,
        additionalData: {
          'branchId': currentUser.currentBranch.id,
          'date': dateKey,
          'netProfit': netProfit.toString(),
        },
      );
    } catch (e) {
      print('Error sending net profit collected notification: $e');
    }
  }
}

