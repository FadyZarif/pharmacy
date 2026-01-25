import 'package:pharmacy/features/report/data/models/daily_report_model.dart';

abstract class ViewReportsState {}

class ViewReportsInitial extends ViewReportsState {}

class ViewReportsLoading extends ViewReportsState {}

class ViewReportsLoaded extends ViewReportsState {
  final List<ShiftReportModel> reports;

  ViewReportsLoaded({required this.reports});
}

class ViewReportsEmpty extends ViewReportsState {}

class ViewReportsError extends ViewReportsState {
  final String message;

  ViewReportsError({required this.message});
}

// Monthly Summary States
class MonthlySummaryLoading extends ViewReportsState {}

class MonthlySummaryLoaded extends ViewReportsState {
  final double totalSales;
  final double totalExpenses;
  final double netProfit;
  final double totalMedicinesExpenses;
  final double totalElectronicPaymentExpenses;
  final double vaultAmount; // مجموع الأرباح غير المحصلة (في الخزنة)
  final double totalSurplus; // مجموع الزيادة
  final double totalDeficit; // مجموع العجز
  final List<ExpenseItem> allExpenses; // جميع المصاريف
  final double? monthlyTarget; // الهدف الشهري

  MonthlySummaryLoaded({
    required this.totalSales,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalMedicinesExpenses,
    required this.totalElectronicPaymentExpenses,
    required this.vaultAmount,
    required this.totalSurplus,
    required this.totalDeficit,
    required this.allExpenses,
    this.monthlyTarget,
  });
}

class MonthlySummaryError extends ViewReportsState {
  final String message;

  MonthlySummaryError({required this.message});
}

// Collection Status States
class CollectionStatusLoading extends ViewReportsState {}

class CollectionStatusLoaded extends ViewReportsState {
  final bool isCollected;

  CollectionStatusLoaded({required this.isCollected});
}

class CollectionStatusUpdated extends ViewReportsState {
  final bool isCollected;

  CollectionStatusUpdated({required this.isCollected});
}

class CollectionStatusError extends ViewReportsState {
  final String message;

  CollectionStatusError({required this.message});
}

