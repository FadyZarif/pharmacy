import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/employee/logic/employee_layout_cubit.dart';
import 'package:pharmacy/features/login/ui/login_screen.dart';
import 'package:pharmacy/features/repair/logic/repair_cubit.dart';
import 'package:pharmacy/features/request/data/services/coverage_shift_service.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';
import 'package:pharmacy/features/request/logic/request_state.dart';
import 'package:pharmacy/features/request/ui/add_request_screen_unified.dart';
import 'package:pharmacy/features/request/ui/widgets/requests_list_view.dart';
import 'package:pharmacy/features/salary/logic/salary_cubit.dart';
import 'package:pharmacy/features/user/logic/users_cubit.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/widgets/profile_circle.dart';
import '../../request/data/models/request_model.dart';
import 'widgets/request_tile.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
  value: getIt<RequestCubit>(),
  child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: ColorsManger.primary,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {

          bool isLogged = await checkIsLogged();
          if (isLogged) {
            setState(() {

            });
          }

        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 30,
              children: [

                /// CurrentUser Info Card
                Container(
                  padding: EdgeInsets.all(16.0),
                  height: 100,
                  decoration: BoxDecoration(
                    color: ColorsManger.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      ProfileCircle(photoUrl: currentUser.photoUrl,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currentUser.currentBranch.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<EmployeeLayoutCubit>().changeBottomNav(4);
                        },
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsManger.primary,
                          // بنفسجي قريب من الصورة
                          foregroundColor: Colors.white,
                          // لون الأيقونة والنص
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
                          ),
                          // Corners دائري بالكامل
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Statistics Section
                Text('Statistics', style: GoogleFonts.pacifico(fontSize: 25)),
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: ColorsManger.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 5),
                          ],
                        ),
                        child: Column(
                          spacing: 10,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.beach_access,
                              color: Colors.green,
                              size: 45,
                            ),
                            Text(
                              currentUser.vocationBalance,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Vacation\nBalance',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: ColorsManger.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 5),
                          ],
                        ),
                        child: Column(
                          spacing: 10,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(Icons.schedule, color: Colors.blue, size: 45),
                            Text(
                              '${currentUser.overTimeHours}h',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Over\nTime',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: ColorsManger.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 5),
                          ],
                        ),
                        child: Column(
                          spacing: 10,
                          children: [
                            Icon(
                              Icons.pending_actions,
                              color: Colors.orange,
                              size: 45,
                            ),
                            BlocBuilder<RequestCubit, RequestState>(
                              buildWhen: (_, current) => current is FetchRequestsSuccess,
                              builder: (context, state) {
                                return Text(
                                  '${getIt<RequestCubit>().pendingRequestsCount}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            Text(
                              'Pending Requests',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                /// Requests Section
                Row(
                  children: [
                    Text('Requests', style: GoogleFonts.pacifico(fontSize: 25)),
                    Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        showNewRequestSheet(context);
                      },
                      icon: const Icon(Icons.add_circle, size: 18),
                      label: const Text('New Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManger.primary,
                        // بنفسجي قريب من الصورة
                        foregroundColor: Colors.white,
                        // لون الأيقونة والنص
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(10),
                        ),
                        // Corners دائري بالكامل
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                RequestsListView(),
              ],
            ),
              ),
        ),
      ),
  ),
);
}

void _showLogoutDialog(BuildContext context) {

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'Logout',
      desc: 'are you sure you want to logout?',
      btnOkText: 'logout',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        _logout(context);
      },
    ).show();
}

Future<void> _logout(BuildContext context) async {
  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // Reset all lazy singletons in GetIt (but keep factories)
    if (getIt.isRegistered<EmployeeLayoutCubit>()) {
      await getIt.resetLazySingleton<EmployeeLayoutCubit>();
    }
    if (getIt.isRegistered<RequestCubit>()) {
      await getIt.resetLazySingleton<RequestCubit>();
    }
    if (getIt.isRegistered<CoverageShiftService>()) {
      await getIt.resetLazySingleton<CoverageShiftService>();
    }
    if (getIt.isRegistered<RepairCubit>()) {
      await getIt.resetLazySingleton<RepairCubit>();
    }
    if (getIt.isRegistered<SalaryCubit>()) {
      await getIt.resetLazySingleton<SalaryCubit>();
    }
    if (getIt.isRegistered<UsersCubit>()) {
      await getIt.resetLazySingleton<UsersCubit>();
    }

    // Update isLogged flag
    isLogged = false;

    // Pop loading dialog
    if (context.mounted) Navigator.pop(context);

    // Navigate to login screen
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (ctx) => const LoginScreen()),
        (route) => false,
      );
    }
  } catch (e) {
    // Pop loading dialog if still showing
    if (context.mounted) Navigator.pop(context);

    // Show error message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
}

Future<void> showNewRequestSheet(BuildContext context) async {
  final items = <RequestItem>[
    RequestItem(
      type: RequestType.annualLeave,
      title: 'Annual Leave',
      subtitle: 'طلب إجازة',
      icon: Icons.flight_takeoff,
      screen: const AddRequestScreenUnified(requestType: RequestType.annualLeave),
    ),
    RequestItem(
      type: RequestType.sickLeave,
      title: 'Sick Leave',
      subtitle: 'طلب إجازة مرضية',
      icon: Icons.local_hospital,
      screen: const AddRequestScreenUnified(requestType: RequestType.sickLeave),
    ),
    RequestItem(
      type: RequestType.extraHours,
      title: 'Extra Hours',
      subtitle: 'طلب ساعات إضافية',
      icon: Icons.access_time,
      screen: const AddRequestScreenUnified(requestType: RequestType.extraHours),
    ),
    RequestItem(
      type: RequestType.coverageShift,
      title: 'Coverage Shift',
      subtitle: 'طلب تغطية وردية',
      icon: Icons.swap_horiz,
      screen: const AddRequestScreenUnified(requestType: RequestType.coverageShift),
    ),
    RequestItem(
      type: RequestType.attend,
      title: 'Attend',
      subtitle: 'طلب حضور',
      icon: Icons.how_to_reg,
      screen: const AddRequestScreenUnified(requestType: RequestType.attend),
    ),
    RequestItem(
      type: RequestType.permission,
      title: 'Permission Early Leave',
      subtitle: 'طلب إذن انصراف بدري',
      icon: Icons.exit_to_app,
      screen: const AddRequestScreenUnified(requestType: RequestType.permission),
    ),
  ];

  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إيه نوع طلبك؟',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...items.map((item) => RequestTile(item: item, requestCubit: getIt<RequestCubit>(),)),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    },
  );
}
