import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/marketing/data/models/marketing_coding_metric_model.dart';
import 'package:pharmacy/features/marketing/data/models/marketing_daily_entry_model.dart';
import 'package:pharmacy/features/marketing/data/models/marketing_metric_model.dart';
import 'package:pharmacy/features/marketing/logic/marketing_state.dart';

class MarketingCubit extends Cubit<MarketingState> {
  MarketingCubit() : super(MarketingInitial());

  final _db = FirebaseFirestore.instance;

  static String? validateCoding(MarketingCodingMetric metric) {
    final items = metric.items
        .where((e) => e.name.isNotEmpty || e.code.isNotEmpty)
        .toList();
    if (items.length != metric.count) {
      return 'New Coding: عدد السجلات لازم يساوي العدد (${metric.count})';
    }
    for (final item in items) {
      if (item.name.isEmpty || item.code.isEmpty) {
        return 'New Coding: الاسم والكود إلزاميان لكل عميل';
      }
    }
    return null;
  }

  static MarketingCodingMetric normalizeCoding(MarketingCodingMetric metric) {
    final items = metric.items
        .where((e) => e.name.trim().isNotEmpty && e.code.trim().isNotEmpty)
        .map(
          (e) => MarketingCodingItem(
            name: e.name.trim(),
            code: e.code.trim(),
          ),
        )
        .toList();
    return MarketingCodingMetric(count: items.length, items: items);
  }

  static String? validateMetric(String label, MarketingMetric metric) {
    final names = metric.names.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
    if (names.length != metric.count) {
      return '$label: عدد الأسماء لازم يساوي العدد (${metric.count})';
    }
    if (metric.count > 0 && names.any((n) => n.isEmpty)) {
      return '$label: الأسماء إلزامية عند وجود عدد';
    }
    return null;
  }

  static MarketingMetric normalizeMetric(MarketingMetric metric) {
    final names = metric.names.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
    return MarketingMetric(count: names.length, names: names);
  }

  Future<List<MarketingDailyEntry>> _fetchEmployeeMonthEntries(DateTime month) async {
    final monthKey = MarketingDailyEntry.monthKeyFrom(month);
    final snapshot = await _db
        .collection('marketing_daily_entries')
        .where('employeeId', isEqualTo: currentUser.uid)
        .where('monthKey', isEqualTo: monthKey)
        .get();

    final entries = snapshot.docs.map(MarketingDailyEntry.fromDoc).toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return entries;
  }

  MarketingMonthSummary _buildMonthSummary(
    DateTime month,
    List<MarketingDailyEntry> entries,
  ) {
    var coding = 0;
    var followers = 0;
    var reviews = 0;
    for (final e in entries) {
      coding += e.newCoding.count;
      followers += e.followers.count;
      reviews += e.reviews.count;
    }
    return MarketingMonthSummary(
      month: DateTime(month.year, month.month, 1),
      entries: entries,
      totalCoding: coding,
      totalFollowers: followers,
      totalReviews: reviews,
      daysRecorded: entries.length,
    );
  }

  Future<void> loadStaffDashboard({DateTime? month}) async {
    emit(MarketingLoading());
    try {
      final now = DateTime.now();
      final selectedMonth = month ?? DateTime(now.year, now.month, 1);
      final todayKey = MarketingDailyEntry.dateKeyFrom(now);
      final docId = MarketingDailyEntry.buildDocId(currentUser.uid, todayKey);
      final todayDoc = await _db.collection('marketing_daily_entries').doc(docId).get();

      MarketingDailyEntry? todayEntry;
      var todayReadOnly = false;
      if (todayDoc.exists) {
        todayEntry = MarketingDailyEntry.fromDoc(todayDoc);
        todayReadOnly = !todayEntry.canEdit;
      }

      final monthEntries = await _fetchEmployeeMonthEntries(selectedMonth);
      final summary = _buildMonthSummary(selectedMonth, monthEntries);

      emit(MarketingStaffDashboardLoaded(
        todayEntry: todayEntry,
        todayReadOnly: todayReadOnly,
        monthSummary: summary,
      ));
    } catch (e) {
      emit(MarketingError('تعذر تحميل البيانات: $e'));
    }
  }

  Future<void> fetchTodayEntry() async {
    emit(MarketingLoading());
    try {
      final today = DateTime.now();
      final dateKey = MarketingDailyEntry.dateKeyFrom(today);
      final docId = MarketingDailyEntry.buildDocId(currentUser.uid, dateKey);
      final doc = await _db.collection('marketing_daily_entries').doc(docId).get();

      if (!doc.exists) {
        emit(MarketingTodayLoaded());
        return;
      }

      final entry = MarketingDailyEntry.fromDoc(doc);
      emit(MarketingTodayLoaded(
        entry: entry,
        isReadOnly: !entry.canEdit,
      ));
    } catch (e) {
      emit(MarketingError('تعذر تحميل سجل اليوم: $e'));
    }
  }

  Future<void> saveTodayEntry({
    required MarketingCodingMetric newCoding,
    required MarketingMetric followers,
    required MarketingMetric reviews,
    MarketingDailyEntry? existing,
  }) async {
    final normalizedCoding = normalizeCoding(newCoding);
    final normalizedFollowers = normalizeMetric(followers);
    final normalizedReviews = normalizeMetric(reviews);

    for (final result in [
      validateCoding(normalizedCoding),
      validateMetric('Followers', normalizedFollowers),
      validateMetric('Reviews', normalizedReviews),
    ]) {
      if (result != null) {
        emit(MarketingError(result));
        return;
      }
    }

    if (existing != null && !existing.canEdit) {
      emit(MarketingError('انتهت مهلة التعديل (24 ساعة)'));
      return;
    }

    emit(MarketingSaveLoading());
    try {
      final today = DateTime.now();
      final dateKey = MarketingDailyEntry.dateKeyFrom(today);
      final monthKey = MarketingDailyEntry.monthKeyFrom(today);
      final docId = MarketingDailyEntry.buildDocId(currentUser.uid, dateKey);
      final isCreate = existing == null;

      final entry = MarketingDailyEntry(
        id: docId,
        employeeId: currentUser.uid,
        employeeName: currentUser.name,
        branchId: currentUser.currentBranch.id,
        branchName: currentUser.currentBranch.name,
        dateKey: dateKey,
        monthKey: monthKey,
        newCoding: normalizedCoding,
        followers: normalizedFollowers,
        reviews: normalizedReviews,
        createdAt: existing?.createdAt ?? today,
        updatedAt: today,
      );

      await _db.collection('marketing_daily_entries').doc(docId).set(
            entry.toMap(isCreate: isCreate),
            SetOptions(merge: !isCreate),
          );

      emit(MarketingSaveSuccess(entry));
      await loadStaffDashboard();
    } catch (e) {
      emit(MarketingError('تعذر حفظ السجل: $e'));
    }
  }

  Future<List<MarketingDailyEntry>> fetchEntriesForDateRaw({
    required DateTime date,
    List<String>? branchIds,
  }) async {
    final dateKey = MarketingDailyEntry.dateKeyFrom(date);
    final snapshot = await _db
        .collection('marketing_daily_entries')
        .where('dateKey', isEqualTo: dateKey)
        .get();

    final entries = _filterByBranches(
      snapshot.docs.map(MarketingDailyEntry.fromDoc).toList(),
      branchIds,
    );
    _sortEntries(entries);
    return entries;
  }

  List<MarketingDailyEntry> _filterByBranches(
    List<MarketingDailyEntry> entries,
    List<String>? branchIds,
  ) {
    if (branchIds == null || branchIds.isEmpty) return entries;
    final allowed = branchIds.toSet();
    return entries.where((e) => allowed.contains(e.branchId)).toList();
  }

  void _sortEntries(List<MarketingDailyEntry> entries) {
    entries.sort((a, b) {
      final branch = a.branchName.compareTo(b.branchName);
      if (branch != 0) return branch;
      final employee = a.employeeName.compareTo(b.employeeName);
      if (employee != 0) return employee;
      return b.dateKey.compareTo(a.dateKey);
    });
  }

  Future<List<MarketingDailyEntry>> fetchEntriesForMonthRaw({
    required DateTime month,
    List<String>? branchIds,
  }) async {
    final monthKey = MarketingDailyEntry.monthKeyFrom(month);
    final snapshot = await _db
        .collection('marketing_daily_entries')
        .where('monthKey', isEqualTo: monthKey)
        .get();

    final entries = _filterByBranches(
      snapshot.docs.map(MarketingDailyEntry.fromDoc).toList(),
      branchIds,
    );
    _sortEntries(entries);
    return entries;
  }

  Future<List<MarketingDailyEntry>> fetchEntriesForRangeRaw({
    required DateTime from,
    required DateTime to,
    List<String>? branchIds,
  }) async {
    final fromKey = MarketingDailyEntry.dateKeyFrom(from);
    final toKey = MarketingDailyEntry.dateKeyFrom(to);
    final snapshot = await _db
        .collection('marketing_daily_entries')
        .where('dateKey', isGreaterThanOrEqualTo: fromKey)
        .where('dateKey', isLessThanOrEqualTo: toKey)
        .get();

    final entries = _filterByBranches(
      snapshot.docs.map(MarketingDailyEntry.fromDoc).toList(),
      branchIds,
    );
    _sortEntries(entries);
    return entries;
  }

  Future<void> fetchEntriesForDate({
    required DateTime date,
    String? branchId,
  }) async {
    emit(MarketingListLoading());
    try {
      if (branchId != null && branchId.isNotEmpty) {
        final entries = await fetchEntriesForDateRaw(
          date: date,
          branchIds: [branchId],
        );
        emit(MarketingListLoaded(entries: entries, selectedDate: date));
        return;
      }

      if (currentUser.isManagement) {
        final branchIds = currentUser.branches.map((b) => b.id).toList();
        if (branchIds.isEmpty) {
          emit(MarketingListLoaded(entries: [], selectedDate: date));
          return;
        }
        final entries = await fetchEntriesForDateRaw(
          date: date,
          branchIds: branchIds,
        );
        emit(MarketingListLoaded(entries: entries, selectedDate: date));
        return;
      }

      final dateKey = MarketingDailyEntry.dateKeyFrom(date);
      final docId = MarketingDailyEntry.buildDocId(currentUser.uid, dateKey);
      final doc = await _db.collection('marketing_daily_entries').doc(docId).get();
      final entries = doc.exists
          ? [MarketingDailyEntry.fromDoc(doc)]
          : <MarketingDailyEntry>[];
      emit(MarketingListLoaded(entries: entries, selectedDate: date));
    } catch (e) {
      emit(MarketingError('تعذر تحميل السجلات: $e'));
    }
  }
}
