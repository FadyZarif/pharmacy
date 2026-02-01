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
  static Future<List<ShiftReportModel>> getBranchShifts(
      DateTime date, String branchId) async {
    final snapshot = await shiftsCollection(date, branchId).get();
    return snapshot.docs
        .map((doc) =>
            ShiftReportModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
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

  /// جلب شيفت الموظف الحالي لليوم
  static Future<ShiftReportModel?> getMyTodayShift(String employeeId) async {
    final today = DateTime.now();
    final branches = await getBranchesForDate(today);

    for (String branchId in branches) {
      final shifts = await getBranchShifts(today, branchId);
      for (var shift in shifts) {
        if (shift.employeeId == employeeId) {
          return shift;
        }
      }
    }

    return null;
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
  static Future<void> updateCollectionStatus(
      DateTime date, String branchId, bool isCollected) async {
    await branchRef(date, branchId).set({
      'isCollected': isCollected,
      'collectedAt': isCollected ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));
  }

  /// متابعة حالة التحصيل real-time
  static Stream<bool> watchCollectionStatus(DateTime date, String branchId) {
    return branchRef(date, branchId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return false;
      final data = snapshot.data() as Map<String, dynamic>;
      return data['isCollected'] ?? false;
    });
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

