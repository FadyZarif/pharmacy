import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';

/// Helper class لإدارة paths و queries الخاصة بالتقارير
class ReportFirestoreHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // ============ Paths ============

  /// Path للتقرير اليومي
  /// daily_reports/{date}
  static String dailyReportPath(DateTime date) {
    return 'daily_reports/${_dateFormat.format(date)}';
  }

  /// Path لفرع معين في يوم معين
  /// daily_reports/{date}/branches/{branchId}
  static String branchPath(DateTime date, String branchId) {
    return '${dailyReportPath(date)}/branches/$branchId';
  }

  /// Path لشيفت معين
  /// daily_reports/{date}/branches/{branchId}/shifts/{shiftType}
  static String shiftPath(DateTime date, String branchId, ShiftType shiftType) {
    return '${branchPath(date, branchId)}/shifts/${shiftType.name}';
  }

  // ============ Document References ============

  /// Reference لمستند التقرير اليومي
  static DocumentReference dailyReportRef(DateTime date) {
    return _firestore.doc(dailyReportPath(date));
  }

  /// Reference لمستند الفرع
  static DocumentReference branchRef(DateTime date, String branchId) {
    return _firestore.doc(branchPath(date, branchId));
  }

  /// Reference لمستند الشيفت
  static DocumentReference shiftRef(
      DateTime date, String branchId, ShiftType shiftType) {
    return _firestore.doc(shiftPath(date, branchId, shiftType));
  }

  // ============ Collection References ============

  /// Reference لكوليكشن الفروع في يوم معين
  static CollectionReference branchesCollection(DateTime date) {
    return _firestore.collection('${dailyReportPath(date)}/branches');
  }

  /// Reference لكوليكشن الشيفتات لفرع معين
  static CollectionReference shiftsCollection(
      DateTime date, String branchId) {
    return _firestore.collection('${branchPath(date, branchId)}/shifts');
  }

  // ============ Queries ============

  /// جلب شيفت معين
  static Future<ShiftReportModel?> getShift(
      DateTime date, String branchId, ShiftType shiftType) async {
    final doc = await shiftRef(date, branchId, shiftType).get();
    if (!doc.exists || doc.data() == null) return null;
    return ShiftReportModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// جلب جميع شيفتات فرع معين ليوم معين
  /// أي مستند تالف أو غير متوافق يُتخطى حتى لا يسقط التطبيق
  static Future<List<ShiftReportModel>> getBranchShifts(
      DateTime date, String branchId) async {
    final snapshot = await shiftsCollection(date, branchId).get();
    final list = <ShiftReportModel>[];
    for (var doc in snapshot.docs) {
      try {
        final data = doc.data();
        if (data == null) continue;
        list.add(ShiftReportModel.fromJson(data as Map<String, dynamic>));
      } catch (_) {
        continue;
      }
    }
    return list;
  }

  /// جلب جميع الفروع ليوم معين
  static Future<List<String>> getBranchesForDate(DateTime date) async {
    final snapshot = await branchesCollection(date).get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// جلب جميع التقارير ليوم معين (كل الفروع والشيفتات)
  static Future<Map<String, List<ShiftReportModel>>> getAllReportsForDate(
      DateTime date) async {
    final branches = await getBranchesForDate(date);
    final Map<String, List<ShiftReportModel>> reports = {};

    for (String branchId in branches) {
      reports[branchId] = await getBranchShifts(date, branchId);
    }

    return reports;
  }

  /// جلب شيفت الموظف الحالي لليوم (أول شيفت يلاقيه)
  /// لو فرع واحد فشل (مثلاً صلاحيات أو بيانات) باقي الفروع تتقرأ عادي
  static Future<ShiftReportModel?> getMyTodayShift(String employeeId) async {
    final all = await getMyShiftsForToday(employeeId);
    return all.isEmpty ? null : all.first;
  }

  /// جلب كل شيفتات الموظف لليوم (صبحية + مسائية + ...) عشان نفضّل شيفت لسه متقفلش
  static Future<List<ShiftReportModel>> getMyShiftsForToday(String employeeId) async {
    final today = DateTime.now();
    List<String> branches;
    try {
      branches = await getBranchesForDate(today);
    } catch (e) {
      return [];
    }

    final list = <ShiftReportModel>[];
    for (String branchId in branches) {
      try {
        final shifts = await getBranchShifts(today, branchId);
        for (var shift in shifts) {
          if (shift.employeeId == employeeId) {
            list.add(shift);
          }
        }
      } catch (e) {
        continue;
      }
    }
    return list;
  }

  // ============ Write Operations ============

  /// حفظ أو تحديث شيفت
  static Future<void> saveShift(
      DateTime date, String branchId, ShiftReportModel shift) async {
    await shiftRef(date, branchId, shift.shiftType)
        .set(shift.toJson(), SetOptions(merge: true));
  }

  /// حذف شيفت
  static Future<void> deleteShift(
      DateTime date, String branchId, ShiftType shiftType) async {
    await shiftRef(date, branchId, shiftType).delete();
  }

  // ============ Calculations ============

  /// حساب إجماليات فرع ليوم معين
  static Future<BranchDailySummary> calculateBranchSummary(
      DateTime date, String branchId) async {
    final shifts = await getBranchShifts(date, branchId);

    double totalDrawer = 0.0;
    double totalExpenses = 0.0;
    int completedShifts = shifts.length;

    for (var shift in shifts) {
      totalDrawer += shift.drawerAmount;
      totalExpenses += shift.totalExpenses;
    }

    return BranchDailySummary(
      branchId: branchId,
      date: date,
      completedShifts: completedShifts,
      totalDrawer: totalDrawer,
      totalExpenses: totalExpenses,
      netAmount: totalDrawer - totalExpenses,
      shifts: shifts,
    );
  }

  /// حساب إجماليات اليوم كامل (كل الفروع)
  static Future<DailySummary> calculateDailySummary(DateTime date) async {
    final allReports = await getAllReportsForDate(date);

    double totalDrawer = 0.0;
    double totalExpenses = 0.0;
    int totalShifts = 0;
    List<BranchDailySummary> branchSummaries = [];

    for (var entry in allReports.entries) {
      final branchSummary = await calculateBranchSummary(date, entry.key);
      branchSummaries.add(branchSummary);

      totalDrawer += branchSummary.totalDrawer;
      totalExpenses += branchSummary.totalExpenses;
      totalShifts += branchSummary.completedShifts;
    }

    return DailySummary(
      date: date,
      totalBranches: allReports.length,
      totalShifts: totalShifts,
      totalDrawer: totalDrawer,
      totalExpenses: totalExpenses,
      netAmount: totalDrawer - totalExpenses,
      branchSummaries: branchSummaries,
    );
  }

  // ============ Real-time Streams ============

  /// متابعة شيفت معين real-time
  static Stream<ShiftReportModel?> watchShift(
      DateTime date, String branchId, ShiftType shiftType) {
    return shiftRef(date, branchId, shiftType).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return ShiftReportModel.fromJson(snapshot.data() as Map<String, dynamic>);
    });
  }

  /// متابعة شيفتات فرع معين real-time
  static Stream<List<ShiftReportModel>> watchBranchShifts(
      DateTime date, String branchId) {
    return shiftsCollection(date, branchId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ShiftReportModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // ============ Collection Status Operations ============

  /// جلب حالة التحصيل لفرع في يوم معين
  static Future<bool> getCollectionStatus(DateTime date, String branchId) async {
    final doc = await branchRef(date, branchId).get();
    if (!doc.exists || doc.data() == null) return false;
    final data = doc.data() as Map<String, dynamic>;
    return data['isCollected'] ?? false;
  }

  /// تحديث حالة التحصيل لفرع في يوم معين
  /// عند التحصيل (isCollected=true) نحفظ المبلغ في البنك المركزي (collected_entries)
  static Future<void> updateCollectionStatus(
    DateTime date,
    String branchId,
    bool isCollected, {
    double? collectedAmount,
    String? branchName,
  }) async {
    final dateKey = _dateFormat.format(date);

    await branchRef(date, branchId).set({
      'isCollected': isCollected,
      'collectedAt': isCollected ? FieldValue.serverTimestamp() : null,
      'collectedAmount': isCollected && collectedAmount != null ? collectedAmount : null,
    }, SetOptions(merge: true));

    final entryId = '${dateKey}_$branchId';
    final entryRef = _firestore.collection('collected_entries').doc(entryId);

    if (isCollected && collectedAmount != null && branchName != null) {
      await entryRef.set({
        'date': dateKey,
        'branchId': branchId,
        'branchName': branchName,
        'amount': collectedAmount,
        'collectedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await entryRef.delete();
    }
  }

  /// متابعة حالة التحصيل real-time
  static Stream<bool> watchCollectionStatus(DateTime date, String branchId) {
    return branchRef(date, branchId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return false;
      final data = snapshot.data() as Map<String, dynamic>;
      return data['isCollected'] ?? false;
    });
  }

  /// إعادة حساب مبلغ التحصيل في البنك لو اليوم/الفرع كان متحصل (Auto-recalculate بعد تعديل شيفت)
  static Future<void> recalculateCollectedAmountIfNeeded(
    DateTime date,
    String branchId,
    String branchName,
  ) async {
    final isCollected = await getCollectionStatus(date, branchId);
    if (!isCollected) return;
    final summary = await calculateBranchSummary(date, branchId);
    await updateCollectionStatus(
      date,
      branchId,
      true,
      collectedAmount: summary.netAmount,
      branchName: branchName,
    );
  }

  // ============ Vault / Bank (البنك المركزي) ============

  /// إجمالي المحصل من كل الفروع (من collected_entries)
  static Future<double> getTotalCollected() async {
    final snapshot = await _firestore.collection('collected_entries').get();
    double total = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      total += (data['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// إجمالي المحصل في مدى تاريخ (للشهر مثلاً)
  static Future<double> getTotalCollectedInRange(DateTime from, DateTime to) async {
    final fromTs = Timestamp.fromDate(DateTime(from.year, from.month, from.day));
    final toTs = Timestamp.fromDate(DateTime(to.year, to.month, to.day, 23, 59, 59, 999));
    final snapshot = await _firestore
        .collection('collected_entries')
        .where('collectedAt', isGreaterThanOrEqualTo: fromTs)
        .where('collectedAt', isLessThanOrEqualTo: toTs)
        .get();
    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// قائمة التحصيلات (للعرض الاختياري).
  /// [from] و [to]: مدى تاريخ اختياري؛ لو الاثنان null ترجع الكل.
  static Future<List<Map<String, dynamic>>> getCollectedEntries({
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _firestore
        .collection('collected_entries')
        .orderBy('collectedAt', descending: true);
    if (from != null) {
      query = query.where(
        'collectedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(from.year, from.month, from.day)),
      );
    }
    if (to != null) {
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
      query = query.where('collectedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }
    final snapshot = await query.get();
    return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Add manual deposit into the central bank
  /// depositItem: 'emad' | 'marhal' | 'other'. When 'other', description is the note.
  static Future<void> addVaultDeposit({
    required double amount,
    required String depositItem,
    String? description,
    required String createdBy,
    String? createdByName,
    String? comment,
    String? attachmentUrl,
  }) async {
    await _firestore.collection('vault_deposits').add({
      'amount': amount,
      'depositItem': depositItem,
      'description': description ?? '',
      'createdBy': createdBy,
      'createdByName': createdByName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'comment': comment ?? '',
      'attachmentUrl': attachmentUrl ?? '',
    });
  }

  /// Get total manual deposits into the bank
  static Future<double> getTotalDeposited() async {
    final snapshot = await _firestore.collection('vault_deposits').get();
    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// إجمالي الإيداع اليدوي في مدى تاريخ (للشهر مثلاً)
  static Future<double> getTotalDepositedInRange(DateTime from, DateTime to) async {
    final fromTs = Timestamp.fromDate(DateTime(from.year, from.month, from.day));
    final toTs = Timestamp.fromDate(DateTime(to.year, to.month, to.day, 23, 59, 59, 999));
    final snapshot = await _firestore
        .collection('vault_deposits')
        .where('createdAt', isGreaterThanOrEqualTo: fromTs)
        .where('createdAt', isLessThanOrEqualTo: toTs)
        .get();
    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// Get list of manual deposits (for display and edit/delete).
  /// [from] and [to]: optional date range (inclusive); if both null, returns all.
  static Future<List<Map<String, dynamic>>> getVaultDeposits({
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _firestore
        .collection('vault_deposits')
        .orderBy('createdAt', descending: true);
    if (from != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(from.year, from.month, from.day)),
      );
    }
    if (to != null) {
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }
    final snapshot = await query.get();
    return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Update a deposit by id
  static Future<void> updateVaultDeposit({
    required String id,
    required double amount,
    required String depositItem,
    String? description,
    String? comment,
    String? attachmentUrl,
  }) async {
    await _firestore.collection('vault_deposits').doc(id).update({
      'amount': amount,
      'depositItem': depositItem,
      'description': description ?? '',
      'comment': comment ?? '',
      'attachmentUrl': attachmentUrl ?? '',
    });
  }

  /// Delete a deposit by id
  static Future<void> deleteVaultDeposit(String id) async {
    await _firestore.collection('vault_deposits').doc(id).delete();
  }

  /// إضافة مصروف من البنك (سحب)
  /// withdrawalItem: 'deposit'|'warehouse'|'company'|'maintenance'|'other'. When 'other', description is the note.
  static Future<void> addVaultExpense({
    required double amount,
    required String withdrawalItem,
    String? description,
    required String createdBy,
    String? createdByName,
    String? comment,
    String? attachmentUrl,
  }) async {
    await _firestore.collection('vault_expenses').add({
      'amount': amount,
      'withdrawalItem': withdrawalItem,
      'description': description ?? '',
      'createdBy': createdBy,
      'createdByName': createdByName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'comment': comment ?? '',
      'attachmentUrl': attachmentUrl ?? '',
    });
  }

  /// جلب مصاريف البنك (السحوبات).
  /// [from] و [to]: مدى تاريخ اختياري؛ لو الاثنان null ترجع الكل.
  static Future<List<Map<String, dynamic>>> getVaultExpenses({
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _firestore
        .collection('vault_expenses')
        .orderBy('createdAt', descending: true);
    if (from != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(from.year, from.month, from.day)),
      );
    }
    if (to != null) {
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }
    final snapshot = await query.get();
    return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// إجمالي المسحوب من البنك
  static Future<double> getTotalWithdrawn() async {
    final snapshot = await _firestore.collection('vault_expenses').get();
    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// إجمالي المسحوب في مدى تاريخ (للشهر مثلاً)
  static Future<double> getTotalWithdrawnInRange(DateTime from, DateTime to) async {
    final fromTs = Timestamp.fromDate(DateTime(from.year, from.month, from.day));
    final toTs = Timestamp.fromDate(DateTime(to.year, to.month, to.day, 23, 59, 59, 999));
    final snapshot = await _firestore
        .collection('vault_expenses')
        .where('createdAt', isGreaterThanOrEqualTo: fromTs)
        .where('createdAt', isLessThanOrEqualTo: toTs)
        .get();
    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// Update a withdrawal (vault expense) by id
  static Future<void> updateVaultExpense({
    required String id,
    required double amount,
    required String withdrawalItem,
    String? description,
    String? comment,
    String? attachmentUrl,
  }) async {
    await _firestore.collection('vault_expenses').doc(id).update({
      'amount': amount,
      'withdrawalItem': withdrawalItem,
      'description': description ?? '',
      'comment': comment ?? '',
      'attachmentUrl': attachmentUrl ?? '',
    });
  }

  /// Delete a withdrawal (vault expense) by id
  static Future<void> deleteVaultExpense(String id) async {
    await _firestore.collection('vault_expenses').doc(id).delete();
  }
}

// ============ Summary Models ============

/// ملخص يومي لفرع واحد
class BranchDailySummary {
  final String branchId;
  final DateTime date;
  final int completedShifts;
  final double totalDrawer;
  final double totalExpenses;
  final double netAmount;
  final List<ShiftReportModel> shifts;

  BranchDailySummary({
    required this.branchId,
    required this.date,
    required this.completedShifts,
    required this.totalDrawer,
    required this.totalExpenses,
    required this.netAmount,
    required this.shifts,
  });
}

/// ملخص يومي لكل الفروع
class DailySummary {
  final DateTime date;
  final int totalBranches;
  final int totalShifts;
  final double totalDrawer;
  final double totalExpenses;
  final double netAmount;
  final List<BranchDailySummary> branchSummaries;

  DailySummary({
    required this.date,
    required this.totalBranches,
    required this.totalShifts,
    required this.totalDrawer,
    required this.totalExpenses,
    required this.netAmount,
    required this.branchSummaries,
  });
}

