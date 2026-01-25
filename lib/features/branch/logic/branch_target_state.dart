abstract class BranchTargetState {}

class BranchTargetInitial extends BranchTargetState {}

class BranchTargetLoading extends BranchTargetState {}

class BranchTargetSuccess extends BranchTargetState {}

class BranchTargetError extends BranchTargetState {
  final String message;

  BranchTargetError(this.message);
}

class BranchTargetFetched extends BranchTargetState {
  final int? monthlyTarget;

  BranchTargetFetched(this.monthlyTarget);
}

