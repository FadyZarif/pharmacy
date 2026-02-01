import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/employee/ui/employee_dashboard_screen.dart';
import 'package:pharmacy/features/repair/ui/add_repair_screen.dart';
import 'package:pharmacy/features/user/ui/profile_screen.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';

import '../../repair/ui/view_repairs_screen.dart';
import '../../report/ui/add_shift_report_screen.dart';
import '../../report/ui/view_reports_screen.dart';
import '../../request/ui/manage_requests_screen.dart';
import '../../salary/ui/add_salary_screen.dart';
import '../../salary/ui/salary_screen.dart';
import '../../user/ui/users_management_screen.dart';
import 'employee_layout_state.dart';


class EmployeeLayoutCubit extends Cubit<EmployeeLayoutState> {
  EmployeeLayoutCubit() : super(EmployeeLayoutInitial());

  List<BottomNavigationBarItem> get bottomNavItems {
    // Manager & Admin
    if (currentUser.role == Role.manager || currentUser.role == Role.admin) {
      return const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            icon: Icon(Icons.build), label: 'Repairs'),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long), label: 'Reports'),
        BottomNavigationBarItem(
            icon: Icon(Icons.event_note), label: 'Requests'),
        BottomNavigationBarItem(
            icon: Icon(Icons.attach_money), label: 'Salary'),
        BottomNavigationBarItem(
            icon: Icon(Icons.groups), label: 'Users'),
      ];
    }

    // SubManager with Requests Permission
    /*if (currentUser.role == Role.subManager && currentUser.hasRequestsPermission) {
      return const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            icon: Icon(Icons.build), label: 'Repair'),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long), label: 'Report'),
        BottomNavigationBarItem(
            icon: Icon(Icons.event_note), label: 'Requests'),
        BottomNavigationBarItem(
            icon: Icon(Icons.attach_money), label: 'Salary'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Profile'),
      ];
    }*/

    // Staff & SubManager without permission
    return <BottomNavigationBarItem>[
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
  }

  List<Widget> get screensList {
    // Manager & Admin - View Mode
    if (currentUser.isManagement) {
      return <Widget>[
        const ViewRepairsScreen(),
        const ViewReportsScreen(),
        const ManageRequestsScreen(),
        currentUser.role==Role.admin? const AddSalaryScreen(): const SalaryScreen(),
        const UsersManagementScreen(),
      ];
    }

    // SubManager with Requests Permission
    /*if (currentUser.role == Role.subManager && currentUser.hasRequestsPermission) {
      return <Widget>[
        const AddRepairScreen(),
        const AddShiftReportScreen(),
        const ManageRequestsScreen(),
        const SalaryScreen(),
        ProfileScreen(user: currentUser),
      ];
    }*/

    // Staff & SubManager without permission - Add Mode
    return <Widget>[
      const AddRepairScreen(),
      const AddShiftReportScreen(),
      const EmployeeDashboardScreen(),
      const SalaryScreen(),
      ProfileScreen(user: currentUser),
    ];
  }

  int currentIndex = 2;

  void changeBottomNav(int i) {
    if( currentIndex == i ) return;
    currentIndex = i;
    emit(LayoutChangeBottomNavState());
  }
}
