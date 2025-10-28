

abstract class RepairState {}

class RepairInitial extends RepairState {}

class RepairFetchDevicesLoading extends RepairState {}
class RepairFetchDevicesSuccess extends RepairState {}
class RepairFetchDevicesError extends RepairState {
  final String error;

  RepairFetchDevicesError(this.error);

}
class AddRepairReportLoading extends RepairState {}
class AddRepairReportSuccess extends RepairState {}
class AddRepairReportError extends RepairState {
  final String error;

  AddRepairReportError(this.error);

}


