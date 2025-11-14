import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/themes/colors.dart';
import '../../employee/logic/employee_layout_cubit.dart';
import '../../employee/ui/employee_layout.dart';
import '../../login/ui/login_screen.dart';
import '../../repair/logic/repair_cubit.dart';
import '../../request/data/services/coverage_shift_service.dart';
import '../../request/logic/request_cubit.dart';
import '../../salary/logic/salary_cubit.dart';
import '../../user/logic/users_cubit.dart';

class BranchSelectionScreen extends StatelessWidget {

  const BranchSelectionScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: const Text('Select Branch',style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: ColorsManger.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Welcome, ${currentUser.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a branch to continue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Branch List
            Expanded(
              child: currentUser.branches.isEmpty
                  ? Center(
                      child: Text(
                        'No branches available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: currentUser.branches.length,
                      itemBuilder: (context, index) {
                        final branch = currentUser.branches[index];
                        return _buildBranchCard(context, branch);
                      },
                    ),
            ),
          ],
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
      /*if (getIt.isRegistered<EmployeeLayoutCubit>()) {
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
      }*/

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
  Widget _buildBranchCard(BuildContext context, Branch branch) {
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Set current branch
          currentUser.currentBranch = branch;
          // Callback
          navigateTo(context, EmployeeLayout());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorsManger.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.store,
                  color: ColorsManger.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Branch Name
              Expanded(
                child: Text(
                  branch.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

