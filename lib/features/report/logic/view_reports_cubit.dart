import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/view_reports_state.dart';

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
      double totalMedicinesExpenses = 0.0;

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
          for (var doc in shiftsSnapshot.docs) {
            final report = ShiftReportModel.fromJson(doc.data());

            totalSales += report.drawerAmount;

            final medicinesExpenses = report.expenses
                .where((expense) => expense.type == ExpenseType.medicines)
                .fold<double>(0.0, (total, expense) => total + expense.amount);

            totalMedicinesExpenses += medicinesExpenses;
          }
        } catch (e) {
          // Continue even if one day fails
          continue;
        }
      }

      emit(MonthlySummaryLoaded(
        totalSales: totalSales,
        totalMedicinesExpenses: totalMedicinesExpenses,
      ));
    } catch (e) {
      emit(MonthlySummaryError(message: e.toString()));
    }
  }
}

