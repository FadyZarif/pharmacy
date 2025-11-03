abstract class EditReportState {}

class EditReportInitial extends EditReportState {}

class EditReportLoading extends EditReportState {}

class EditReportSuccess extends EditReportState {}

class EditReportError extends EditReportState {
  final String message;

  EditReportError({required this.message});
}

