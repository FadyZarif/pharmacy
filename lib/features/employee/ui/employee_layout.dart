import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/features/employee/logic/employee_layout_cubit.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';
import '../../../core/themes/colors.dart';
import '../logic/employee_layout_state.dart';

class EmployeeLayout extends StatelessWidget {
  const EmployeeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers:[
        BlocProvider<EmployeeLayoutCubit>(
          create: (context) => getIt<EmployeeLayoutCubit>(),
        ),
        BlocProvider<RequestCubit>(create: (context) => getIt<RequestCubit>()..fetchRequests(),)

      ],
      child: Builder(
          builder: (context) {
            EmployeeLayoutCubit employeeLayoutCubit = getIt<EmployeeLayoutCubit>();

            return BlocBuilder<EmployeeLayoutCubit, EmployeeLayoutState>(
              builder: (context, state) {
                return Scaffold(
                  body: employeeLayoutCubit
                      .screensList[employeeLayoutCubit.currentIndex],
                  bottomNavigationBar: BottomNavigationBar(
                    type: BottomNavigationBarType.shifting,
                    unselectedItemColor: Colors.grey,
                    selectedItemColor: ColorsManger.primary,
                    items: employeeLayoutCubit.bottomNavItems,
                    onTap: (i) {
                      employeeLayoutCubit.changeBottomNav(i);
                    },
                    currentIndex: employeeLayoutCubit.currentIndex,
                  ),
                );
              },
            );
          }
      ),
    );
  }
}
