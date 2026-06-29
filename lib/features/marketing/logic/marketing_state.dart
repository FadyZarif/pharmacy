import 'package:pharmacy/features/marketing/data/models/marketing_daily_entry_model.dart';

abstract class MarketingState {}

class MarketingInitial extends MarketingState {}

class MarketingLoading extends MarketingState {}

class MarketingTodayLoaded extends MarketingState {
  final MarketingDailyEntry? entry;
  final bool isReadOnly;

  MarketingTodayLoaded({this.entry, this.isReadOnly = false});
}

class MarketingSaveLoading extends MarketingState {}

class MarketingSaveSuccess extends MarketingState {
  final MarketingDailyEntry entry;

  MarketingSaveSuccess(this.entry);
}

class MarketingError extends MarketingState {
  final String message;

  MarketingError(this.message);
}

class MarketingListLoading extends MarketingState {}

class MarketingListLoaded extends MarketingState {
  final List<MarketingDailyEntry> entries;
  final DateTime selectedDate;

  MarketingListLoaded({
    required this.entries,
    required this.selectedDate,
  });
}

class MarketingMonthSummary {
  final DateTime month;
  final List<MarketingDailyEntry> entries;
  final int totalCoding;
  final int totalFollowers;
  final int totalReviews;
  final int daysRecorded;

  const MarketingMonthSummary({
    required this.month,
    required this.entries,
    required this.totalCoding,
    required this.totalFollowers,
    required this.totalReviews,
    required this.daysRecorded,
  });
}

class MarketingStaffDashboardLoaded extends MarketingState {
  final MarketingDailyEntry? todayEntry;
  final bool todayReadOnly;
  final MarketingMonthSummary monthSummary;

  MarketingStaffDashboardLoaded({
    this.todayEntry,
    this.todayReadOnly = false,
    required this.monthSummary,
  });
}
