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
  final double totalMedicinesWithInvoicesExpenses;
  final double totalElectronicPaymentExpenses;
  final double totalInstapayExpenses;
  final double totalWalletExpenses;
  final double totalVisaExpenses;
  final double totalDeliveryExpenses;
  final Map<String, double> branchDeliveryTotals;
  final Map<String, BranchElectronicBreakdown> branchElectronicBreakdowns;
  final double vaultAmount;
  final double totalSurplus;
  final double totalDeficit;
  final List<ExpenseItem> allExpenses;
  final Map<String, BranchSummary> branchSummaries; // ملخص كل فرع
  final double? monthlyTarget; // الهدف الشهري الموحد
  final Map<String, double> branchMonthlyTargets; // الهدف الشهري لكل فرع
  final double totalPurchases; // إجمالي مشتريات الفروع لنفس الشهر
  final Map<String, double> branchMonthlyPurchases; // مشتريات كل فرع لنفس الشهر

  ConsolidatedReportsLoaded({
    required this.totalSales,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalMedicinesExpenses,
    this.totalMedicinesWithInvoicesExpenses = 0.0,
    required this.totalElectronicPaymentExpenses,
    this.totalInstapayExpenses = 0.0,
    this.totalWalletExpenses = 0.0,
    this.totalVisaExpenses = 0.0,
    this.totalDeliveryExpenses = 0.0,
    this.branchDeliveryTotals = const {},
    this.branchElectronicBreakdowns = const {},
    required this.vaultAmount,
    required this.totalSurplus,
    required this.totalDeficit,
    required this.allExpenses,
    required this.branchSummaries,
    this.monthlyTarget,
    this.branchMonthlyTargets = const {},
    this.totalPurchases = 0.0,
    this.branchMonthlyPurchases = const {},
  });
}

class BranchElectronicBreakdown {
  final String branchId;
  final String branchName;
  final double instapay;
  final double wallet;
  final double visa;

  const BranchElectronicBreakdown({
    required this.branchId,
    required this.branchName,
    this.instapay = 0.0,
    this.wallet = 0.0,
    this.visa = 0.0,
  });

  double get total => instapay + wallet + visa;
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

