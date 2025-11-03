import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/salary/data/models/employee_monthly_salary.dart';
import 'package:pharmacy/features/salary/data/models/month_salary_model.dart';
import 'package:pharmacy/features/salary/data/models/salary_model.dart';
import 'package:pharmacy/features/salary/logic/salary_state.dart';

class SalaryCubit extends Cubit<SalaryState> {
  SalaryCubit() : super(SalaryInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _salarySubscription;


  /// جلب بيانات مرتب شهر معين
  Future<void> fetchSalaryByMonthKey(String monthKey) async {
    emit(SalaryLoading());

    try {
      final salary = await getSalaryByMonthKey(monthKey);

      if (salary == null) {
        emit(SalaryError(error: 'No data available for this month'));
      } else {
        emit(SingleSalaryLoaded(salary: salary));
      }
    } catch (e) {
      emit(SalaryError(error: e.toString()));
    }
  }

  /// جلب مرتب شهر معين بـ monthKey (مثل: "2024-11")
  Future<EmployeeMonthlySalary?> getSalaryByMonthKey(String monthKey) async {
    try {
      // جلب معلومات الشهر
      final monthDoc = await _db
          .collection('salaries')
          .doc(monthKey)
          .get();

      if (!monthDoc.exists) {
        return null;
      }

      final monthData = monthDoc.data()!;
      if (monthData['uploadedAt'] != null) {
        monthData['uploadedAt'] = (monthData['uploadedAt'] as Timestamp).toDate().toIso8601String();
      }

      final monthInfo = MonthSalaryModel.fromJson(monthData);

      // جلب بيانات الموظف
      final employeeDoc = await _db
          .collection('salaries')
          .doc(monthKey)
          .collection('employees')
          .doc(currentUser.uid)
          .get();

      if (!employeeDoc.exists) {
        return null;
      }

      final salaryData = SalaryModel.fromJson(employeeDoc.data()!);

      return EmployeeMonthlySalary(
        monthInfo: monthInfo,
        salaryData: salaryData,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> close() {
    _salarySubscription?.cancel();
    return super.close();
  }
}

