import 'package:pharmacy/features/report/data/models/daily_report_model.dart';

abstract class ShiftReportState {}

// Initial State
class ShiftReportInitial extends ShiftReportState {}

// Loading States
class ShiftReportLoading extends ShiftReportState {}

class ShiftReportLoadingMyShift extends ShiftReportState {}

// Success States
class ShiftReportLoaded extends ShiftReportState {
  final ShiftReportModel report;

  ShiftReportLoaded(this.report);
}

class ShiftReportSubmitted extends ShiftReportState {
  final ShiftReportModel report;

  ShiftReportSubmitted(this.report);
}

class ShiftReportUpdated extends ShiftReportState {}

// Error States
class ShiftReportError extends ShiftReportState {
  final String message;

  ShiftReportError(this.message);
}

// Validation States
class ShiftReportValidationError extends ShiftReportState {
  final String message;

  ShiftReportValidationError(this.message);
}

// Expense Management States
class ExpenseAdded extends ShiftReportState {
  final List<ExpenseItem> expenses;

  ExpenseAdded(this.expenses);
}

class ExpenseRemoved extends ShiftReportState {
  final List<ExpenseItem> expenses;

  ExpenseRemoved(this.expenses);
}

// File Upload States
class AttachmentUploading extends ShiftReportState {}

class AttachmentUploaded extends ShiftReportState {
  final String attachmentUrl;

  AttachmentUploaded(this.attachmentUrl);
}

class AttachmentRemoved extends ShiftReportState {}

class AttachmentUploadError extends ShiftReportState {
  final String message;

  AttachmentUploadError(this.message);
}

// Check if shift already exists
class ShiftAlreadyExists extends ShiftReportState {
  final ShiftReportModel existingReport;

  ShiftAlreadyExists(this.existingReport);
}

class NoExistingShift extends ShiftReportState {}

