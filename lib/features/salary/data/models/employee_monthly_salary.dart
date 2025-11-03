import 'package:pharmacy/features/salary/data/models/month_salary_model.dart';
import 'package:pharmacy/features/salary/data/models/salary_model.dart';

/// Model that combines month metadata with employee salary data
class EmployeeMonthlySalary {
  final MonthSalaryModel monthInfo;
  final SalaryModel salaryData;

  EmployeeMonthlySalary({
    required this.monthInfo,
    required this.salaryData,
  });

  /// الحصول على اسم الشهر
  String get monthName => monthInfo.monthName;

  /// الحصول على تاريخ الرفع
  DateTime? get uploadedAt => monthInfo.uploadedAt;

  /// الحصول على الموظف
  String get employeeUid => salaryData.employeeUid;

  /// الحصول على صافي المرتب
  String get netSalary => salaryData.netSalary;
}

