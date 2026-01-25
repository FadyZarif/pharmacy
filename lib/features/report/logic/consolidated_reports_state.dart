import 'package:pharmacy/features/report/data/models/daily_report_model.dart';

abstract class ConsolidatedReportsState {}

class ConsolidatedReportsInitial extends ConsolidatedReportsState {}

class ConsolidatedReportsLoading extends ConsolidatedReportsState {
  final String currentBranchName;
  final int completedBranches;
  final int totalBranches;

  ConsolidatedReportsLoading({
    required this.currentBranchName,
    required this.completedBranches,
    required this.totalBranches,
  });
}

class ConsolidatedReportsLoaded extends ConsolidatedReportsState {
  final double totalSales;
  final double totalExpenses;
  final double netProfit;
  final double totalMedicinesExpenses;
  final double totalElectronicPaymentExpenses;
  final double vaultAmount;
  final double totalSurplus;
  final double totalDeficit;
  final List<ExpenseItem> allExpenses;
  final Map<String, BranchSummary> branchSummaries; // ملخص كل فرع

  ConsolidatedReportsLoaded({
    required this.totalSales,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalMedicinesExpenses,
    required this.totalElectronicPaymentExpenses,
    required this.vaultAmount,
    required this.totalSurplus,
    required this.totalDeficit,
    required this.allExpenses,
    required this.branchSummaries,
  });
}

class ConsolidatedReportsError extends ConsolidatedReportsState {
  final String message;

  ConsolidatedReportsError({required this.message});
}

/// ملخص فرع واحد
class BranchSummary {
  final String branchId;
  final String branchName;
  final double totalSales;
  final double totalExpenses;
  final double netProfit;

  BranchSummary({
    required this.branchId,
    required this.branchName,
    required this.totalSales,
    required this.totalExpenses,
    required this.netProfit,
  });
}

