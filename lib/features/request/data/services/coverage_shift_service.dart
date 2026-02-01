import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacy/features/request/data/models/coverage_shift_model.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';

class CoverageShiftService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create coverage shift record when request is approved
  Future<void> createCoverageShift({
    required String requestId,
    required DateTime date,
    required String employee1Id,
    required Branch employee1OriginalBranch,
    required Branch employee1TempBranch,
    required String employee2Id,
    required Branch employee2OriginalBranch,
    required Branch employee2TempBranch,
  }) async {
    final docId = '${employee1Id}_${employee2Id}_${date.millisecondsSinceEpoch}';

    final coverageShift = CoverageShiftModel(
      id: docId,
      requestId: requestId,
      date: date,
      employee1Id: employee1Id,
      employee1OriginalBranchId: employee1OriginalBranch.id,
      employee1OriginalBranchName: employee1OriginalBranch.name,
      employee1TempBranchId: employee1TempBranch.id,
      employee1TempBranchName: employee1TempBranch.name,
      employee2Id: employee2Id,
      employee2OriginalBranchId: employee2OriginalBranch.id,
      employee2OriginalBranchName: employee2OriginalBranch.name,
      employee2TempBranchId: employee2TempBranch.id,
      employee2TempBranchName: employee2TempBranch.name,
    );

    await _db.collection('coverage_shifts').doc(docId).set(coverageShift.toJson());
  }

  /// Delete coverage shift (when request is rejected or deleted)
  Future<void> deleteCoverageShift(String requestId) async {
    final snapshot = await _db
        .collection('coverage_shifts')
        .where('requestId', isEqualTo: requestId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Get today's coverage shift for employee
  Future<CoverageShiftModel?> getTodayCoverageShift(String employeeId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Check if employee1
    var snapshot = await _db
        .collection('coverage_shifts')
        .where('employee1Id', isEqualTo: employeeId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return CoverageShiftModel.fromJson(snapshot.docs.first.data());
    }

    // Check if employee2
    snapshot = await _db
        .collection('coverage_shifts')
        .where('employee2Id', isEqualTo: employeeId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return CoverageShiftModel.fromJson(snapshot.docs.first.data());
    }

    return null;
  }

  /// Get coverage shift for specific date
  Future<CoverageShiftModel?> getCoverageShiftForDate(
    String employeeId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Check if employee1
    var snapshot = await _db
        .collection('coverage_shifts')
        .where('employee1Id', isEqualTo: employeeId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return CoverageShiftModel.fromJson(snapshot.docs.first.data());
    }

    // Check if employee2
    snapshot = await _db
        .collection('coverage_shifts')
        .where('employee2Id', isEqualTo: employeeId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return CoverageShiftModel.fromJson(snapshot.docs.first.data());
    }

    return null;
  }

  /// Apply temporary branch to user based on coverage shift
  Future<Branch?> getTemporaryBranch(String employeeId) async {
    final coverageShift = await getTodayCoverageShift(employeeId);

    if (coverageShift == null) return null;

    if (coverageShift.employee1Id == employeeId) {
      return Branch(
        id: coverageShift.employee1TempBranchId,
        name: coverageShift.employee1TempBranchName,
      );
    } else if (coverageShift.employee2Id == employeeId) {
      return Branch(
        id: coverageShift.employee2TempBranchId,
        name: coverageShift.employee2TempBranchName,
      );
    }

    return null;
  }
}

