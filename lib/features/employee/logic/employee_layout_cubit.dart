import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/employee/ui/employee_dashboard_screen.dart';
import 'package:pharmacy/features/repair/ui/repair_report_screen.dart';
import 'package:pharmacy/features/user/ui/profile_screen.dart';
import 'package:pharmacy/features/employee/ui/salary_screen.dart';

import '../../report/ui/add_shift_report_screen.dart';
import 'employee_layout_state.dart';


class EmployeeLayoutCubit extends Cubit<EmployeeLayoutState> {
  EmployeeLayoutCubit() : super(EmployeeLayoutInitial());

  List<BottomNavigationBarItem> bottomNavItems = [
    const BottomNavigationBarItem(
        icon: Icon(Icons.build), label: 'Repair'),
    const BottomNavigationBarItem(
        icon: Icon(Icons.attach_money), label: 'Report'),
    const BottomNavigationBarItem(
        icon: Icon(Icons.home), label: 'Dashboard'),
    const BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet), label: 'Salary'),
    const BottomNavigationBarItem(
        icon: Icon(Icons.person), label: 'Profile'),
  ];
  List<Widget> screensList = [
    RepairReportScreen(),
    AddShiftReportScreen(),
    EmployeeDashboardScreen(),
    SalaryScreen(),
    ProfileScreen(user: currentUser),
  ];
  int currentIndex = 2;

  void changeBottomNav(int i) {
    if( currentIndex == i ) return;
    currentIndex = i;
    emit(LayoutChangeBottomNavState());
  }
}
