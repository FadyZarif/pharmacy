import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/employee/ui/employee_dashboard_screen.dart';
import 'package:pharmacy/features/repair/ui/repair_report_screen.dart';
import 'package:pharmacy/features/user/ui/profile_screen.dart';

import '../../report/ui/add_shift_report_screen.dart';
import '../../salary/ui/salary_screen.dart';
import 'employee_layout_state.dart';


class EmployeeLayoutCubit extends Cubit<EmployeeLayoutState> {
  EmployeeLayoutCubit() : super(EmployeeLayoutInitial());

  List<BottomNavigationBarItem> get bottomNavItems {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
          icon: Icon(Icons.build), label: 'Repair'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long), label: 'Report'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.home), label: 'Dashboard'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.attach_money), label: 'Salary'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person), label: 'Profile'),
    ];

    // إضافة تبويب للـ subManager فقط
    // if (currentUser.role == Role.subManager) {
    //   items.insert(2, const BottomNavigationBarItem(
    //       icon: Icon(Icons.assessment), label: 'Reports'));
    // }

    return items;
  }

  List<Widget> get screensList {
    final screens = <Widget>[
      RepairReportScreen(),
      AddShiftReportScreen(),
      EmployeeDashboardScreen(),
      SalaryScreen(),
      ProfileScreen(user: currentUser),
    ];

    // إضافة شاشة للـ subManager فقط
    // if (currentUser.role == Role.subManager) {
    //   screens.insert(2, const ViewReportsScreen());
    // }

    return screens;
  }

  int currentIndex = 2;

  void changeBottomNav(int i) {
    if( currentIndex == i ) return;
    currentIndex = i;
    emit(LayoutChangeBottomNavState());
  }
}
