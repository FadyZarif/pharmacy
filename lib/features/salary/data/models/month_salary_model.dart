import 'package:json_annotation/json_annotation.dart';

import '../../../../core/helpers/server_timestamp_helper.dart';

part 'month_salary_model.g.dart';

/// Model for the month document that contains metadata about the salary upload
@JsonSerializable(explicitToJson: true)
class MonthSalaryModel {
  final String monthKey; // Document ID: "2024_11"
  final String monthName; // اسم الشهر: "نوفمبر 2024"
  final int year; // السنة: 2024
  final int month; // الشهر: 11
  @ServerTimestampOnNullConverter()
  final DateTime? uploadedAt; // تاريخ الرفع
  final String? uploadedBy; // Admin UID
  final int? employeeCount; // عدد الموظفين
  final String? notes; // ملاحظات

  MonthSalaryModel({
    required this.monthKey,
    required this.monthName,
    required this.year,
    required this.month,
    this.uploadedAt,
    this.uploadedBy,
    this.employeeCount,
    this.notes,
  });

  factory MonthSalaryModel.fromJson(Map<String, dynamic> json) =>
      _$MonthSalaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$MonthSalaryModelToJson(this);

  /// إنشاء monthKey من السنة والشهر
  static String createMonthKey(int year, int month) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  /// تحويل monthKey إلى اسم شهر بالعربي
  static String getMonthNameArabic(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  /// Factory constructor لإنشاء من سنة وشهر
  factory MonthSalaryModel.create({
    required int year,
    required int month,
    String? uploadedBy,
    int? employeeCount,
    String? notes,
  }) {
    final monthKey = createMonthKey(year, month);
    final monthName = '${getMonthNameArabic(month)} $year';

    return MonthSalaryModel(
      monthKey: monthKey,
      monthName: monthName,
      year: year,
      month: month,
      uploadedAt: DateTime.now(),
      uploadedBy: uploadedBy,
      employeeCount: employeeCount,
      notes: notes,
    );
  }
}

