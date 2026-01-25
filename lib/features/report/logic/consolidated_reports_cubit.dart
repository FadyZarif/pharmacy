import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/features/report/data/helpers/report_firestore_helper.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/consolidated_reports_state.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';

class ConsolidatedReportsCubit extends Cubit<ConsolidatedReportsState> {
  ConsolidatedReportsCubit() : super(ConsolidatedReportsInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// جلب ملخص يومي لجميع الفروع
  Future<void> fetchDailyConsolidatedReports(
    List<Branch> branches,
    DateTime selectedDate,
  ) async {
    emit(ConsolidatedReportsInitial());

    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

      double totalSales = 0.0;
      double totalExpenses = 0.0;
      double totalMedicinesExpenses = 0.0;
      double totalElectronicPaymentExpenses = 0.0;
      double vaultAmount = 0.0;
      double totalSurplus = 0.0;
      double totalDeficit = 0.0;
      List<ExpenseItem> allExpenses = [];
      Map<String, BranchSummary> branchSummaries = {};

      int completedBranches = 0;

      for (var branch in branches) {
        // Emit loading state for current branch
        emit(ConsolidatedReportsLoading(
          currentBranchName: branch.name,
          completedBranches: completedBranches,
          totalBranches: branches.length,
        ));

        try {
          // جلب كل الشيفتات للفرع في هذا اليوم
          final shiftsSnapshot = await _db
              .collection('daily_reports')
              .doc(dateKey)
              .collection('branches')
              .doc(branch.id)
              .collection('shifts')
              .get();

          double branchSales = 0.0;
          double branchExpenses = 0.0;

          for (var doc in shiftsSnapshot.docs) {
            final report = ShiftReportModel.fromJson(doc.data());

            branchSales += report.drawerAmount;
            branchExpenses += report.totalExpenses;
            totalSales += report.drawerAmount;
            totalExpenses += report.totalExpenses;

            totalMedicinesExpenses += report.medicineExpenses;
            totalElectronicPaymentExpenses += report.electronicWalletExpenses;

            allExpenses.addAll(report.expenses);

            // حساب الزيادة والعجز
            if (report.computerDifferenceType == ComputerDifferenceType.excess) {
              totalSurplus += report.computerDifference;
            } else if (report.computerDifferenceType ==
                ComputerDifferenceType.shortage) {
              totalDeficit += report.computerDifference;
            }
          }

          // Check if this day's profit is collected
          if (branchSales > 0 || branchExpenses > 0) {
            final isCollected = await ReportFirestoreHelper.getCollectionStatus(
              selectedDate,
              branch.id,
            );

            if (!isCollected) {
              final dailyNetProfit = branchSales - branchExpenses;
              vaultAmount += dailyNetProfit;
            }
          }

          // حفظ ملخص الفرع
          branchSummaries[branch.id] = BranchSummary(
            branchId: branch.id,
            branchName: branch.name,
            totalSales: branchSales,
            totalExpenses: branchExpenses,
            netProfit: branchSales - branchExpenses,
          );

          completedBranches++;
        } catch (e) {
          print('Error fetching data for branch ${branch.name}: $e');
          // استمر حتى لو فشل فرع واحد
          completedBranches++;
          continue;
        }
      }

      final netProfit = totalSales - totalExpenses;

      emit(ConsolidatedReportsLoaded(
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
        totalMedicinesExpenses: totalMedicinesExpenses,
        totalElectronicPaymentExpenses: totalElectronicPaymentExpenses,
        vaultAmount: vaultAmount,
        totalSurplus: totalSurplus,
        totalDeficit: totalDeficit,
        allExpenses: allExpenses,
        branchSummaries: branchSummaries,
      ));
    } catch (e) {
      emit(ConsolidatedReportsError(message: e.toString()));
    }
  }

  /// جلب ملخص شهري لجميع الفروع
  Future<void> fetchMonthlyConsolidatedReports(
    List<Branch> branches,
    DateTime selectedDate,
  ) async {
    emit(ConsolidatedReportsInitial());

    try {
      final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);

      double totalSales = 0.0;
      double totalExpenses = 0.0;
      double totalMedicinesExpenses = 0.0;
      double totalElectronicPaymentExpenses = 0.0;
      double vaultAmount = 0.0;
      double totalSurplus = 0.0;
      double totalDeficit = 0.0;
      List<ExpenseItem> allExpenses = [];
      Map<String, BranchSummary> branchSummaries = {};

      int completedBranches = 0;

      for (var branch in branches) {
        // Emit loading state for current branch
        emit(ConsolidatedReportsLoading(
          currentBranchName: branch.name,
          completedBranches: completedBranches,
          totalBranches: branches.length,
        ));

        try {
          double branchSales = 0.0;
          double branchExpenses = 0.0;

          // Fetch reports for each day in the month
          for (int day = 1; day <= lastDay.day; day++) {
            final date = DateTime(selectedDate.year, selectedDate.month, day);
            final dateStr = DateFormat('yyyy-MM-dd').format(date);

            try {
              final shiftsSnapshot = await _db
                  .collection('daily_reports')
                  .doc(dateStr)
                  .collection('branches')
                  .doc(branch.id)
                  .collection('shifts')
                  .get();

              double dailySales = 0.0;
              double dailyExpenses = 0.0;

              for (var doc in shiftsSnapshot.docs) {
                final report = ShiftReportModel.fromJson(doc.data());

                dailySales += report.drawerAmount;
                dailyExpenses += report.totalExpenses;
                branchSales += report.drawerAmount;
                branchExpenses += report.totalExpenses;
                totalSales += report.drawerAmount;
                totalExpenses += report.totalExpenses;

                totalMedicinesExpenses += report.medicineExpenses;
                totalElectronicPaymentExpenses += report.electronicWalletExpenses;

                allExpenses.addAll(report.expenses);

                if (report.computerDifferenceType ==
                    ComputerDifferenceType.excess) {
                  totalSurplus += report.computerDifference;
                } else if (report.computerDifferenceType ==
                    ComputerDifferenceType.shortage) {
                  totalDeficit += report.computerDifference;
                }
              }

              // Check if this day's profit is collected
              if (dailySales > 0 || dailyExpenses > 0) {
                final isCollected =
                    await ReportFirestoreHelper.getCollectionStatus(
                  date,
                  branch.id,
                );

                if (!isCollected) {
                  final dailyNetProfit = dailySales - dailyExpenses;
                  vaultAmount += dailyNetProfit;
                }
              }
            } catch (e) {
              continue;
            }
          }

          // حفظ ملخص الفرع
          branchSummaries[branch.id] = BranchSummary(
            branchId: branch.id,
            branchName: branch.name,
            totalSales: branchSales,
            totalExpenses: branchExpenses,
            netProfit: branchSales - branchExpenses,
          );

          completedBranches++;
        } catch (e) {
          print('Error fetching data for branch ${branch.name}: $e');
          completedBranches++;
          continue;
        }
      }

      final netProfit = totalSales - totalExpenses;

      emit(ConsolidatedReportsLoaded(
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
        totalMedicinesExpenses: totalMedicinesExpenses,
        totalElectronicPaymentExpenses: totalElectronicPaymentExpenses,
        vaultAmount: vaultAmount,
        totalSurplus: totalSurplus,
        totalDeficit: totalDeficit,
        allExpenses: allExpenses,
        branchSummaries: branchSummaries,
      ));
    } catch (e) {
      emit(ConsolidatedReportsError(message: e.toString()));
    }
  }
}

