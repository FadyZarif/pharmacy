
abstract class RequestState {}

final class RequestInitial extends RequestState {}

final class AddRequestLoading extends RequestState {}
final class AddRequestSuccess extends RequestState {}
final class AddRequestFailure extends RequestState {
  final String error;
    AddRequestFailure({required this.error});
}

final class FetchRequestsLoading extends RequestState {}
final class FetchRequestsSuccess extends RequestState {}
final class FetchRequestsFailure extends RequestState {
  final String error;
    FetchRequestsFailure({required this.error});
}

final class FetchBranchesWithEmployeesLoading extends RequestState {}
final class FetchBranchesWithEmployeesSuccess extends RequestState {}
final class FetchBranchesWithEmployeesFailure extends RequestState {
  final String error;
  FetchBranchesWithEmployeesFailure({required this.error});
}
