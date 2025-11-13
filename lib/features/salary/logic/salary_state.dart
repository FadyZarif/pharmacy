import 'package:pharmacy/features/salary/data/models/employee_monthly_salary.dart';
import 'package:pharmacy/features/salary/data/models/month_salary_model.dart';

abstract class SalaryState {}

class SalaryInitial extends SalaryState {}

// حالات جلب بيانات المرتبات
class SalaryLoading extends SalaryState {}

// بيانات مرتب شهر واحد
class SingleSalaryLoaded extends SalaryState {
  final EmployeeMonthlySalary salary;

  SingleSalaryLoaded({required this.salary});
}

class SalaryError extends SalaryState {
  final String error;

  SalaryError({required this.error});
}

// حالات رفع البيانات من Excel
class SalaryUploading extends SalaryState {}

class SalaryUploadSuccess extends SalaryState {
  final int employeeCount;

  SalaryUploadSuccess({required this.employeeCount});
}

// حالة جلب معلومات الشهر المرفوع مسبقاً
class MonthInfoLoaded extends SalaryState {
  final MonthSalaryModel? monthInfo;

  MonthInfoLoaded({required this.monthInfo});
}

