part of 'job_opportunity_cubit.dart';

abstract class JobOpportunityState {}

class JobOpportunityInitial extends JobOpportunityState {}

class JobOpportunityLoading extends JobOpportunityState {}
class JobOpportunityAdding extends JobOpportunityState {}
class JobOpportunityDeleting extends JobOpportunityState {}

class JobOpportunityAdded extends JobOpportunityState {
  final String message;
  JobOpportunityAdded(this.message);
}

class JobOpportunityLoaded extends JobOpportunityState {
  final List<JobOpportunityModel> opportunities;
  JobOpportunityLoaded(this.opportunities);
}

class JobOpportunityError extends JobOpportunityState {
  final String error;
  JobOpportunityError(this.error);
}
class JobOpportunityAddingError extends JobOpportunityState {
  final String error;
  JobOpportunityAddingError(this.error);
}
