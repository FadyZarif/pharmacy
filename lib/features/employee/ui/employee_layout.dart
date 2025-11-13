import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/features/employee/logic/employee_layout_cubit.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';
import 'package:pharmacy/features/user/logic/users_cubit.dart';
import '../../../core/themes/colors.dart';
import '../../repair/logic/repair_cubit.dart';
import '../logic/employee_layout_state.dart';

class EmployeeLayout extends StatelessWidget {
  const EmployeeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmployeeLayoutCubit>(
      create: (context) => getIt<EmployeeLayoutCubit>(),
      child: Builder(
          builder: (context) {
            EmployeeLayoutCubit employeeLayoutCubit = getIt<EmployeeLayoutCubit>();

            return BlocBuilder<EmployeeLayoutCubit, EmployeeLayoutState>(
              builder: (context, state) {
                return Scaffold(
                  body: PopScope(
                    onPopInvokedWithResult: (b,s) async {
                      // Prevent back navigation
                      if (getIt.isRegistered<EmployeeLayoutCubit>()) {
                        await getIt.resetLazySingleton<EmployeeLayoutCubit>();
                      }
                      if (getIt.isRegistered<RepairCubit>()) {
                        await getIt.resetLazySingleton<RepairCubit>();
                      }
                      if (getIt.isRegistered<RequestCubit>()) {
                        await getIt.resetLazySingleton<RequestCubit>();
                      }
                      if (getIt.isRegistered<UsersCubit>()) {
                        await getIt.resetLazySingleton<UsersCubit>();
                      }

                    },
                    child: employeeLayoutCubit
                        .screensList[employeeLayoutCubit.currentIndex],
                  ),
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
