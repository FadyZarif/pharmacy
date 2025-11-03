import 'package:pharmacy/features/salary/data/models/employee_monthly_salary.dart';

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


