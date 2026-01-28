import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import '../../../core/themes/colors.dart';
import '../../employee/ui/employee_layout.dart';
import '../../login/ui/login_screen.dart';
import '../../report/logic/consolidated_reports_cubit.dart';
import '../../report/logic/consolidated_reports_state.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../report/data/models/daily_report_model.dart';

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

            // All Branches Monthly Report (Management Only)
            if (currentUser.isAdmin || currentUser.uid == '7DUwUuQ0rIUUb94NCK2vdnrZCLo1')
              ...[
                _buildAllBranchesReportCard(context),
                const SizedBox(height: 16),
              ],
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
                  color: ColorsManger.primary.withValues(alpha: 0.1),
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

  Widget _buildAllBranchesReportCard(BuildContext context) {
    return Card(
      color: ColorsManger.primary,
      elevation: 6,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _showConsolidatedReportsOptions(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                ColorsManger.primary,
                ColorsManger.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assessment,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Branches Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View monthly summary for all branches',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// عرض خيارات التقرير الموحد
  void _showConsolidatedReportsOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'All Branches Report',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select report type',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Report Button
            _buildReportTypeCard(
              context: context,
              title: 'Daily Report',
              subtitle: 'View consolidated daily report for all branches',
              icon: Icons.today,
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _selectDateAndShowReport(context, isMonthly: false);
              },
            ),
            const SizedBox(height: 16),

            // Monthly Report Button
            _buildReportTypeCard(
              context: context,
              title: 'Monthly Report',
              subtitle: 'View consolidated monthly report for all branches',
              icon: Icons.calendar_month,
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _selectDateAndShowReport(context, isMonthly: true);
              },
            ),
            // const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  /// اختيار التاريخ وعرض التقرير
  Future<void> _selectDateAndShowReport(BuildContext context,
      {required bool isMonthly}) async {
    // Get the navigator before async gap
    final navigator = Navigator.of(context);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      helpText: isMonthly ? 'Select Month' : 'Select Date',
    );

    if (picked != null) {
      // Use the navigator's context instead
      _showConsolidatedReportDialog(navigator.context, picked, isMonthly: isMonthly);
    }
  }

  /// عرض تقرير موحد لكل الفروع
  void _showConsolidatedReportDialog(BuildContext context, DateTime selectedDate,
      {required bool isMonthly}) {
    final cubit = ConsolidatedReportsCubit();

    // Start fetching data
    if (isMonthly) {
      cubit.fetchMonthlyConsolidatedReports(currentUser.branches, selectedDate);
    } else {
      cubit.fetchDailyConsolidatedReports(currentUser.branches, selectedDate);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: BlocConsumer<ConsolidatedReportsCubit, ConsolidatedReportsState>(
          listener: (context, state) {
            if (state is ConsolidatedReportsError) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ConsolidatedReportsLoading) {
              return _buildLoadingDialog(state);
            } else if (state is ConsolidatedReportsLoaded) {
              return _buildConsolidatedReportDialog(
                  state, selectedDate, isMonthly);
            }
            // Initial loading
            return const Center(
              child: CircularProgressIndicator(color: ColorsManger.primary),
            );
          },
        ),
      ),
    ).then((_) => cubit.close());
  }

  /// Dialog عرض التحميل مع المؤشر
  Widget _buildLoadingDialog(ConsolidatedReportsLoading state) {
    final progress = state.completedBranches / state.totalBranches;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.analytics,
              size: 48,
              color: ColorsManger.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(ColorsManger.primary),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Text(
              'Processing: ${state.currentBranchName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${state.completedBranches} / ${state.totalBranches} branches completed',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog عرض التقرير الموحد
  Widget _buildConsolidatedReportDialog(
    ConsolidatedReportsLoaded state,
    DateTime selectedDate,
    bool isMonthly,
  ) {
    final dateTitle = isMonthly
        ? DateFormat('MMMM yyyy').format(selectedDate)
        : DateFormat('MMM dd, yyyy').format(selectedDate);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Builder(
          builder: (dialogContext) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.business_center,
                    color: ColorsManger.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Branches Report',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateTitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Total Sales
                      _buildSummaryCard(
                        title: 'Total Sales',
                        amount: state.totalSales,
                        icon: Icons.attach_money,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),

                      // Target Achievement Card (if monthly target is set and it's monthly report)
                      if (isMonthly && state.monthlyTarget != null) ...[
                        _buildTargetAchievementCard(
                          totalSales: state.totalSales,
                          monthlyTarget: state.monthlyTarget!,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Total Expenses
                      InkWell(
                        onTap: () {
                          Navigator.pop(dialogContext); // Close dialog
                          _showExpensesBottomSheet(dialogContext, state.allExpenses);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: _buildSummaryCard(
                          title: 'Total Expenses',
                          amount: state.totalExpenses,
                          icon: Icons.money_off,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Net Profit
                      _buildSummaryCard(
                        title: 'Net Profit',
                        amount: state.netProfit,
                        icon: state.netProfit >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: state.netProfit >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(height: 16),

                      // Medicines Expenses
                      _buildSummaryCard(
                        title: 'Medicines Expenses',
                        amount: state.totalMedicinesExpenses,
                        icon: Icons.medication,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 16),

                      // Electronic Payment
                      _buildSummaryCard(
                        title: 'Electronic Payment',
                        amount: state.totalElectronicPaymentExpenses,
                        icon: Icons.credit_card,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 16),

                      // Total Excess
                      _buildSummaryCard(
                        title: 'Total Excess',
                        amount: state.totalSurplus,
                        icon: Icons.add_circle,
                        color: Colors.lightGreen,
                      ),
                      const SizedBox(height: 16),

                      // Total Shortage
                      _buildSummaryCard(
                        title: 'Total Shortage',
                        amount: state.totalDeficit,
                        icon: Icons.remove_circle,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),

                      // Vault Amount
                      _buildSummaryCard(
                        title: 'Vault Amount (Uncollected)',
                        amount: state.vaultAmount,
                        icon: Icons.account_balance_wallet,
                        color: Colors.amber,
                        subtitle: 'Total net profit not yet collected',
                      ),
                      const SizedBox(height: 24),

                      // Branch Details Expansion
                      ExpansionTile(
                        leading: const Icon(Icons.store, color: ColorsManger.primary),
                        title: const Text(
                          'Branch Details',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children: state.branchSummaries.values.map((branch) {
                          return ListTile(
                            title: Text(branch.branchName),
                            subtitle: Text(
                              'Sales: ${branch.totalSales.toStringAsFixed(1)} | '
                              'Expenses: ${branch.totalExpenses.toStringAsFixed(1)}',
                            ),
                            trailing: Text(
                              'EGP ${branch.netProfit.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: branch.netProfit >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManger.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة تحقيق الهدف الشهري
  Widget _buildTargetAchievementCard({
    required double totalSales,
    required double monthlyTarget,
  }) {
    final achievementPercentage = (totalSales / monthlyTarget * 100).clamp(0, 999);
    final isAchieved = achievementPercentage >= 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAchieved ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAchieved ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAchieved ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAchieved ? Icons.check_circle : Icons.trending_up,
                  color: isAchieved ? Colors.green : Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Achievement (All Branches)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${achievementPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isAchieved ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: EGP ${monthlyTarget.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (achievementPercentage / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isAchieved ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'EGP ${amount.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// عرض المصاريف في bottom sheet
  void _showExpensesBottomSheet(BuildContext context, List<ExpenseItem> expenses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: ColorsManger.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Expenses',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${expenses.length} items',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'EGP ${expenses.fold<double>(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorsManger.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            // Expenses list
            Expanded(
              child: expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return _buildExpenseCard(expense: expense);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual expense card
  Widget _buildExpenseCard({required ExpenseItem expense}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorsManger.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt,
              color: ColorsManger.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        expense.description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (expense.fileUrl != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          final url = Uri.parse(expense.fileUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ColorsManger.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            expense.fileUrl!.toLowerCase().contains('pdf')
                                ? Icons.picture_as_pdf
                                : Icons.image,
                            color: ColorsManger.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    expense.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'EGP ${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorsManger.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

