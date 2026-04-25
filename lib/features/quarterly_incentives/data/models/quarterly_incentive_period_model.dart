import 'package:cloud_firestore/cloud_firestore.dart';

/// Metadata for one uploaded quarterly incentives period (`quarterly_incentives/{periodKey}`).
enum IncentivePeriodType { monthly, quarterly }

class QuarterlyIncentivePeriodModel {
  final String periodKey;
  final int year;
  final int? month;
  final int quarter;
  final IncentivePeriodType periodType;
  final String uploadedSheetName;
  final DateTime? uploadedAt;
  final String? uploadedBy;
  final int? employeeCount;
  final String? notes;

  QuarterlyIncentivePeriodModel({
    required this.periodKey,
    required this.year,
    this.month,
    required this.quarter,
    required this.periodType,
    required this.uploadedSheetName,
    this.uploadedAt,
    this.uploadedBy,
    this.employeeCount,
    this.notes,
  });

  static String createQuarterlyPeriodKey(int year, int quarter) =>
      '$year-Q${quarter.clamp(1, 4)}';

  static String createMonthlyPeriodKey(int year, int month) =>
      '$year-${month.clamp(1, 12).toString().padLeft(2, '0')}';

  String get displayPeriod {
    if (periodType == IncentivePeriodType.monthly && month != null) {
      return '${month!.toString().padLeft(2, '0')}/$year';
    }
    return 'Q$quarter/$year';
  }

  factory QuarterlyIncentivePeriodModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final ts = data['uploadedAt'];
    return QuarterlyIncentivePeriodModel(
      periodKey: doc.id,
      year: (data['year'] as num?)?.toInt() ?? 0,
      month: (data['month'] as num?)?.toInt(),
      quarter: (data['quarter'] as num?)?.toInt() ?? 0,
      periodType: ((data['periodType'] as String?) == 'monthly')
          ? IncentivePeriodType.monthly
          : IncentivePeriodType.quarterly,
      uploadedSheetName: (data['uploadedSheetName'] as String?) ?? '',
      uploadedAt: ts is Timestamp ? ts.toDate() : null,
      uploadedBy: data['uploadedBy'] as String?,
      employeeCount: (data['employeeCount'] as num?)?.toInt(),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'year': year,
      if (month != null) 'month': month,
      'quarter': quarter,
      'periodType': periodType == IncentivePeriodType.monthly
          ? 'monthly'
          : 'quarterly',
      'uploadedSheetName': uploadedSheetName,
      'uploadedAt': FieldValue.serverTimestamp(),
      'uploadedBy': uploadedBy,
      'employeeCount': employeeCount,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
