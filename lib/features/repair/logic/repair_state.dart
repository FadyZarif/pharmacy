import 'package:pharmacy/features/repair/data/models/repair_model.dart';

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

class FetchRepairsLoading extends RepairState {}
class FetchRepairsSuccess extends RepairState {
  final List<RepairModel> repairs;

  FetchRepairsSuccess(this.repairs);
}
class FetchRepairsError extends RepairState {
  final String error;

  FetchRepairsError(this.error);

}


