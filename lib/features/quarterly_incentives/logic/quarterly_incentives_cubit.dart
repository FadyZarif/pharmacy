import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/enums/notification_type.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/services/notification_service.dart';
import 'package:pharmacy/features/quarterly_incentives/data/models/employee_quarterly_incentive_bundle.dart';
import 'package:pharmacy/features/quarterly_incentives/data/models/employee_quarterly_incentive_model.dart';
import 'package:pharmacy/features/quarterly_incentives/data/models/quarterly_incentive_period_model.dart';
import 'package:pharmacy/features/quarterly_incentives/logic/quarterly_incentives_state.dart';

class QuarterlyIncentivesCubit extends Cubit<QuarterlyIncentivesState> {
  QuarterlyIncentivesCubit() : super(QuarterlyIncentivesInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sheet names inside an .xlsx (after decoding).
  static List<String> sheetNamesFromBytes(Uint8List fileBytes) {
    final excel = Excel.decodeBytes(fileBytes);
    return excel.tables.keys.toList();
  }

  Future<void> fetchPeriodInfo(String periodKey) async {
    try {
      final snap =
          await _db.collection('quarterly_incentives').doc(periodKey).get();
      if (!snap.exists) {
        emit(QuarterlyIncentivePeriodInfoLoaded(period: null));
        return;
      }
      emit(
        QuarterlyIncentivePeriodInfoLoaded(
          period: QuarterlyIncentivePeriodModel.fromDoc(snap),
        ),
      );
    } catch (e) {
      emit(QuarterlyIncentivesError(message: e.toString()));
    }
  }

  Future<void> fetchPeriods() async {
    emit(QuarterlyIncentivesLoading());
    try {
      final snap = await _db.collection('quarterly_incentives').get();
      final list = snap.docs
          .map(QuarterlyIncentivePeriodModel.fromDoc)
          .toList();
      // Keep latest periods first without requiring Firestore composite indexes.
      list.sort((a, b) => b.periodKey.compareTo(a.periodKey));
      final limited = list.length > 48 ? list.sublist(0, 48) : list;
      emit(QuarterlyIncentivesPeriodsLoaded(periods: limited));
    } catch (e) {
      emit(QuarterlyIncentivesError(message: e.toString()));
    }
  }

  Future<void> fetchMyIncentiveForPeriod(String periodKey) async {
    emit(QuarterlyIncentivesLoading());
    try {
      final periodRef = _db.collection('quarterly_incentives').doc(periodKey);
      final periodSnap = await periodRef.get();
      if (!periodSnap.exists) {
        emit(QuarterlyIncentivesError(message: 'Period not found'));
        return;
      }
      final period = QuarterlyIncentivePeriodModel.fromDoc(periodSnap);
      final empSnap = await periodRef
          .collection('employees')
          .doc(currentUser.uid)
          .get();
      if (!empSnap.exists) {
        emit(QuarterlyIncentivesEmpty(period: period));
        return;
      }
      final data = EmployeeQuarterlyIncentiveModel.fromDoc(empSnap);
      emit(
        QuarterlyIncentiveSingleLoaded(
          bundle: EmployeeQuarterlyIncentiveBundle(period: period, data: data),
        ),
      );
    } catch (e) {
      emit(QuarterlyIncentivesError(message: e.toString()));
    }
  }

  /// Admin uploads [sheetName] only from [fileBytes]. Data rows start at Excel row 4 (index 3).
  Future<void> uploadQuarterlyIncentivesFromExcel({
    required Uint8List fileBytes,
    required int year,
    required int quarter,
    int? month,
    IncentivePeriodType periodType = IncentivePeriodType.quarterly,
    required String sheetName,
    String? notes,
  }) async {
    if (!currentUser.isAdmin) {
      emit(QuarterlyIncentivesError(message: 'Only admin can upload incentives'));
      return;
    }

    emit(QuarterlyIncentivesUploading());
    try {
      final excel = Excel.decodeBytes(fileBytes);
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) {
        emit(
          QuarterlyIncentivesError(
            message: 'Sheet not found or empty: $sheetName',
          ),
        );
        return;
      }

      const int firstDataRowIndex = 3;
      final rows = sheet.rows;
      if (rows.length <= firstDataRowIndex) {
        emit(QuarterlyIncentivesError(message: 'No data rows in sheet'));
        return;
      }

      final periodKey = periodType == IncentivePeriodType.monthly
          ? QuarterlyIncentivePeriodModel.createMonthlyPeriodKey(
              year,
              month ?? 1,
            )
          : QuarterlyIncentivePeriodModel.createQuarterlyPeriodKey(
              year,
              quarter,
            );
      final List<EmployeeQuarterlyIncentiveModel> records = [];

      for (int i = firstDataRowIndex; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((c) => c?.value == null)) continue;
        try {
          final uid = _getCellValue(row, 1).trim();
          if (uid.isEmpty || uid == '0') continue;

          final basicSalary = _toDouble(_getCellValue(row, 7));
          final monthlyIncentive = _toDouble(_getCellValue(row, 8));
          final bonuses = _toDouble(_getCellValue(row, 9));
          final adminIncentive = _toDouble(_getCellValue(row, 10));
          final eideya = _toDouble(_getCellValue(row, 11));
          final quarterlyShiftDeficitDeduction = _toDouble(_getCellValue(row, 12));
          final listIncentive = _toDouble(_getCellValue(row, 14));
          final restIncrease = _toDouble(_getCellValue(row, 15));
          final creditExchange = _toDouble(_getCellValue(row, 16));
          final cashExchange = _toDouble(_getCellValue(row, 17));
          final expiryAmount = _toDouble(_getCellValue(row, 20));
          final quantityAdjustments = _toDouble(_getCellValue(row, 22));
          final inventoryIncreaseCode = _toDouble(_getCellValue(row, 23));
          final deficitCarryover = _toDouble(_getCellValue(row, 25));
          final branchAdjustment = _toDouble(_getCellValue(row, 26));
          final branchEmployeeCount = _toDouble(_getCellValue(row, 28));

          // Always compute derived columns in code; ignore formula/result columns from Excel.
          final lineTotal = basicSalary +
              monthlyIncentive +
              bonuses +
              adminIncentive +
              eideya -
              quarterlyShiftDeficitDeduction;
          final totalExchange = creditExchange + cashExchange;
          final rate02 = totalExchange * 0.02;
          final expiry25Percent = expiryAmount * 0.25;
          final inventoryFinalValue = quantityAdjustments + inventoryIncreaseCode;
          final totalPlusMinus = listIncentive +
              restIncrease +
              rate02 -
              inventoryFinalValue +
              deficitCarryover +
              branchAdjustment;
          final perCapitaShare = branchEmployeeCount > 0
              ? (totalPlusMinus / branchEmployeeCount)
              : 0.0;
          final netDue = lineTotal + perCapitaShare;

          final model = EmployeeQuarterlyIncentiveModel(
            employeeUid: uid,
            pharmacyCode: _getCellValue(row, 2),
            pharmacyName: _getCellValue(row, 3),
            acc: _getCellValue(row, 4),
            nameEnglish: _getCellValue(row, 5),
            nameArabic: _getCellValue(row, 6),
            basicSalary: _fmt(basicSalary),
            monthlyIncentive: _fmt(monthlyIncentive),
            bonuses: _fmt(bonuses),
            adminIncentive: _fmt(adminIncentive),
            eideya: _fmt(eideya),
            quarterlyShiftDeficitDeduction: _fmt(quarterlyShiftDeficitDeduction),
            lineTotal: _fmt(lineTotal),
            listIncentive: _fmt(listIncentive),
            restIncrease: _fmt(restIncrease),
            creditExchange: _fmt(creditExchange),
            cashExchange: _fmt(cashExchange),
            totalExchange: _fmt(totalExchange),
            rate02: _fmt(rate02),
            expiryAmount: _fmt(expiryAmount),
            expiry25Percent: _fmt(expiry25Percent),
            quantityAdjustments: _fmt(quantityAdjustments),
            inventoryIncreaseCode: _fmt(inventoryIncreaseCode),
            inventoryFinalValue: _fmt(inventoryFinalValue),
            deficitCarryover: _fmt(deficitCarryover),
            branchAdjustment: _fmt(branchAdjustment),
            totalPlusMinus: _fmt(totalPlusMinus),
            branchEmployeeCount: _fmt(branchEmployeeCount),
            perCapitaShare: _fmt(perCapitaShare),
            netDue: _fmt(netDue),
            notes: _getCellValue(row, 31),
          );
          records.add(model);
        } catch (e) {
          // ignore bad row
        }
      }

      if (records.isEmpty) {
        emit(
          QuarterlyIncentivesError(
            message: 'No valid employee rows (check UID column and header row)',
          ),
        );
        return;
      }

      final monthRef = _db.collection('quarterly_incentives').doc(periodKey);
      final oldSnap = await monthRef.collection('employees').get();
      if (oldSnap.docs.isNotEmpty) {
        const chunk = 450;
        for (var i = 0; i < oldSnap.docs.length; i += chunk) {
          final batch = _db.batch();
          final end = (i + chunk > oldSnap.docs.length)
              ? oldSnap.docs.length
              : i + chunk;
          for (var j = i; j < end; j++) {
            batch.delete(oldSnap.docs[j].reference);
          }
          await batch.commit();
        }
      }

      final trimmedNotes = notes?.trim();
      final periodMeta = QuarterlyIncentivePeriodModel(
        periodKey: periodKey,
        year: year,
        month: periodType == IncentivePeriodType.monthly ? month : null,
        quarter: quarter,
        periodType: periodType,
        uploadedSheetName: sheetName,
        uploadedBy: currentUser.uid,
        employeeCount: records.length,
        notes: (trimmedNotes == null || trimmedNotes.isEmpty)
            ? null
            : trimmedNotes,
      );

      await monthRef.set(periodMeta.toFirestore());

      const maxOps = 450;
      for (var i = 0; i < records.length; i += maxOps) {
        final batch = _db.batch();
        final end = (i + maxOps > records.length) ? records.length : i + maxOps;
        for (var j = i; j < end; j++) {
          final r = records[j];
          batch.set(
            monthRef.collection('employees').doc(r.employeeUid),
            r.toFirestore(),
          );
        }
        await batch.commit();
      }

      await _sendIncentiveUploadedNotification(
        records,
        periodKey,
        year,
        quarter,
        periodType,
        month,
      );

      emit(QuarterlyIncentivesUploadSuccess(employeeCount: records.length));
    } catch (e) {
      emit(QuarterlyIncentivesError(message: 'Upload failed: $e'));
    }
  }

  Future<void> _sendIncentiveUploadedNotification(
    List<EmployeeQuarterlyIncentiveModel> records,
    String periodKey,
    int year,
    int quarter,
    IncentivePeriodType periodType,
    int? month,
  ) async {
    try {
      final notificationService = getIt<NotificationService>();
      final ids = records
          .map((e) => e.employeeUid)
          .where((id) => id.isNotEmpty && id != '0')
          .toList();
      if (ids.isEmpty) return;
      final body = periodType == IncentivePeriodType.monthly
          ? 'تم رفع حوافز شهر ${month?.toString().padLeft(2, '0') ?? '--'} لسنة $year'
          : 'تم رفع حوافز الربع $quarter لسنة $year';
      await notificationService.sendNotificationToUsers(
        userIds: ids,
        title: 'تم رفع الحوافز',
        body: body,
        type: NotificationType.quarterlyIncentiveAdded,
        additionalData: {
          'periodKey': periodKey,
          'year': year.toString(),
          'quarter': quarter.toString(),
          if (month != null) 'month': month.toString(),
          'periodType': periodType == IncentivePeriodType.monthly
              ? 'monthly'
              : 'quarterly',
        },
      );
    } catch (e) {
      // non-fatal
    }
  }

  String _getCellValue(List<Data?> row, int index) {
    if (index >= row.length) return '';
    final cell = row[index];
    if (cell == null || cell.value == null) return '';

    final value = cell.value;
    if (value is num) return value.toString();
    if (value is String) {
      return (value as String).trim();
    }
    if (value is FormulaCellValue) {
      return '';
    }
    final str = value.toString().trim();
    return str;
  }

  double _toDouble(String value) {
    final cleaned = value.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return 0.0;
    return double.tryParse(cleaned) ?? 0.0;
  }

  String _fmt(double value) => value.toStringAsFixed(2);
}
