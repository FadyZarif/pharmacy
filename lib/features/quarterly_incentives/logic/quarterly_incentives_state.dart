import 'package:pharmacy/features/quarterly_incentives/data/models/employee_quarterly_incentive_bundle.dart';
import 'package:pharmacy/features/quarterly_incentives/data/models/quarterly_incentive_period_model.dart';

abstract class QuarterlyIncentivesState {}

class QuarterlyIncentivesInitial extends QuarterlyIncentivesState {}

class QuarterlyIncentivesLoading extends QuarterlyIncentivesState {}

class QuarterlyIncentivesPeriodsLoaded extends QuarterlyIncentivesState {
  final List<QuarterlyIncentivePeriodModel> periods;

  QuarterlyIncentivesPeriodsLoaded({required this.periods});
}

class QuarterlyIncentiveSingleLoaded extends QuarterlyIncentivesState {
  final EmployeeQuarterlyIncentiveBundle bundle;

  QuarterlyIncentiveSingleLoaded({required this.bundle});
}

class QuarterlyIncentivesEmpty extends QuarterlyIncentivesState {
  final QuarterlyIncentivePeriodModel period;

  QuarterlyIncentivesEmpty({required this.period});
}

class QuarterlyIncentivesError extends QuarterlyIncentivesState {
  final String message;

  QuarterlyIncentivesError({required this.message});
}

class QuarterlyIncentivesUploading extends QuarterlyIncentivesState {}

class QuarterlyIncentivesUploadSuccess extends QuarterlyIncentivesState {
  final int employeeCount;

  QuarterlyIncentivesUploadSuccess({required this.employeeCount});
}

class QuarterlyIncentivePeriodInfoLoaded extends QuarterlyIncentivesState {
  final QuarterlyIncentivePeriodModel? period;

  QuarterlyIncentivePeriodInfoLoaded({required this.period});
}
