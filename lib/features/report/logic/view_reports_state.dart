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
  final double totalMedicinesExpenses;

  MonthlySummaryLoaded({
    required this.totalSales,
    required this.totalMedicinesExpenses,
  });
}

class MonthlySummaryError extends ViewReportsState {
  final String message;

  MonthlySummaryError({required this.message});
}

