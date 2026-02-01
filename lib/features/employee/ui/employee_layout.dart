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
      child: BlocBuilder<EmployeeLayoutCubit, EmployeeLayoutState>(
        builder: (context, state) {
          final cubit = context.read<EmployeeLayoutCubit>();
          final items = cubit.bottomNavItems;
          final screens = cubit.screensList;

          return Scaffold(
            extendBody: true,
            body: PopScope(
              onPopInvokedWithResult: (didPop, result) async {
                // Preserve existing behavior: clean lazy singletons on pop.
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
                  final slide = Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(fade);
                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(cubit.currentIndex),
                  child: screens[cubit.currentIndex],
                ),
              ),
            ),
            bottomNavigationBar: _GlassBottomNav(
              selectedIndex: cubit.currentIndex,
              items: items,
              onSelected: cubit.changeBottomNav,
            ),
          );
        },
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onSelected;

  const _GlassBottomNav({
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final destinations = items
        .map(
          (i) => NavigationDestination(
            icon: i.icon,
            selectedIcon: i.activeIcon,
            label: i.label ?? '',
          ),
        )
        .toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ColorsManger.primary.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: ColorsManger.primary.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 66,
            backgroundColor: Colors.transparent,
            indicatorColor: ColorsManger.primary.withValues(alpha: 0.14),
            surfaceTintColor: Colors.transparent,
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
