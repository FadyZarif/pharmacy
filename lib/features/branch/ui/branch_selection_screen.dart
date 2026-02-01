import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/widgets/profile_circle.dart';
import 'package:pharmacy/features/request/data/models/request_model.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import 'package:pharmacy/features/user/ui/edit_user_screen.dart';
import '../../../core/themes/colors.dart';
import '../../employee/ui/employee_layout.dart';
import '../../login/ui/login_screen.dart';
import '../../report/logic/consolidated_reports_cubit.dart';
import '../../report/logic/consolidated_reports_state.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../report/data/models/daily_report_model.dart';

class BranchSelectionScreen extends StatefulWidget {
  static const _pagePadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  const BranchSelectionScreen({super.key});

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  final Map<String, int> _pendingCounts = {};
  final Set<String> _pendingLoading = {};

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fetchPendingCounts();
  }

  Future<void> _fetchPendingCounts() async {
    // Fetch pending request counts per branch (fast aggregate query).
    // Runs in background; UI shows a tiny loader until ready.
    final branches = currentUser.branches;
    if (branches.isEmpty) return;

    setState(() {
      _pendingLoading.addAll(branches.map((b) => b.id));
    });

    Future<int> countForBranch(String branchId) async {
      final query = FirebaseFirestore.instance
          .collection('requests')
          .where('employeeBranchId', isEqualTo: branchId)
          .where('status', isEqualTo: RequestStatus.pending.name);
      final snap = await query.count().get();
      return snap.count ?? 0;
    }

    // Firestore doesn't support "group by", so we query per branch.
    // If you have many branches, we can optimize later with a pre-aggregated collection.
    await Future.wait(
      branches.map((b) async {
        try {
          final c = await countForBranch(b.id);
          if (!mounted) return;
          setState(() {
            _pendingCounts[b.id] = c;
            _pendingLoading.remove(b.id);
          });
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _pendingCounts[b.id] = 0;
            _pendingLoading.remove(b.id);
          });
        }
      }),
    );
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _openMyProfile() async {
    if (!currentUser.isManagement) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditUserScreen(user: currentUser)),
    );

    if (updated == true) {
      await checkIsLogged();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F8FF), Color(0xFFEAFBFF), Color(0xFFF2ECFF)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: BranchSelectionScreen._pagePadding,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: ColorsManger.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _openMyProfile,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentUser.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black.withValues(
                                          alpha: 0.62,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentUser.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black.withValues(
                                          alpha: 0.42,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              ProfileCircle(
                                photoUrl: currentUser.photoUrl,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: ColorsManger.primary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout),
                      tooltip: 'Logout',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                        foregroundColor: ColorsManger.primary,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Please select a branch to continue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorsManger.grey,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // All Branches Monthly Report (Management Only)
              if (currentUser.isAdmin ||
                  currentUser.uid == '7DUwUuQ0rIUUb94NCK2vdnrZCLo1') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAllBranchesReportCard(context),
                ),
                const SizedBox(height: 12),
              ],

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: currentUser.branches.isEmpty
                      ? Center(
                          child: Text(
                            'No branches available',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Requested: always show 2 columns.
                            // (Works nicely on phones and web; cards adapt by aspect ratio.)
                            const crossAxisCount = 2;
                            final width = constraints.maxWidth;
                            final height = constraints.maxHeight;
                            // Make cards more compact on web (avoid huge/tall cards).
                            final baseMainAxisExtent = width >= 1100
                                ? 170.0
                                : width >= 800
                                ? 185.0
                                : width >= 560
                                ? 200.0
                                : 160.0;

                            // On mobile, try to fit all branches without scrolling (when reasonable)
                            // by computing tile height from available space + number of rows.
                            final branchCount = currentUser.branches.length;
                            final rows = (branchCount / crossAxisCount)
                                .ceil()
                                .clamp(1, 99);
                            const gridTop = 6.0;
                            const gridBottom = 12.0;
                            const mainAxisSpacing = 12.0;
                            final fitExtent =
                                (height -
                                    (gridTop + gridBottom) -
                                    (mainAxisSpacing * (rows - 1))) /
                                rows;
                            final mainAxisExtent = width < 560
                                ? fitExtent.clamp(120.0, baseMainAxisExtent)
                                : baseMainAxisExtent;

                            return GridView.builder(
                              padding: const EdgeInsets.only(
                                top: gridTop,
                                bottom: gridBottom,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: mainAxisSpacing,
                                    mainAxisExtent: mainAxisExtent,
                                  ),
                              itemCount: currentUser.branches.length,
                              itemBuilder: (context, index) {
                                final branch = currentUser.branches[index];
                                final compact = width < 420;
                                return _buildAnimatedBranchCard(
                                  context: context,
                                  branch: branch,
                                  index: index,
                                  pendingCount: _pendingCounts[branch.id],
                                  pendingLoading: _pendingLoading.contains(
                                    branch.id,
                                  ),
                                  compact: compact,
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
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
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAnimatedBranchCard({
    required BuildContext context,
    required Branch branch,
    required int index,
    required int? pendingCount,
    required bool pendingLoading,
    required bool compact,
  }) {
    final start = (index * 0.06).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: _enterController,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.10),
          end: Offset.zero,
        ).animate(anim),
        child: _BranchTile(
          branch: branch,
          pendingCount: pendingCount,
          pendingLoading: pendingLoading,
          compact: compact,
          onTap: () {
            currentUser.currentBranch = branch;
            navigateTo(context, const EmployeeLayout());
          },
        ),
      ),
    );
  }

  Widget _buildAllBranchesReportCard(BuildContext context) {
    return Card(
      color: ColorsManger.primary,
      elevation: 6,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select report type',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
  Future<void> _selectDateAndShowReport(
    BuildContext context, {
    required bool isMonthly,
  }) async {
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
      _showConsolidatedReportDialog(
        navigator.context,
        picked,
        isMonthly: isMonthly,
      );
    }
  }

  /// عرض تقرير موحد لكل الفروع
  void _showConsolidatedReportDialog(
    BuildContext context,
    DateTime selectedDate, {
    required bool isMonthly,
  }) {
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
                state,
                selectedDate,
                isMonthly,
              );
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
            const Icon(Icons.analytics, size: 48, color: ColorsManger.primary),
            const SizedBox(height: 16),
            const Text(
              'Loading Reports',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                ColorsManger.primary,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Text(
              'Processing: ${state.currentBranchName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${state.completedBranches} / ${state.totalBranches} branches completed',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                          _showExpensesBottomSheet(
                            dialogContext,
                            state.allExpenses,
                          );
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
                        leading: const Icon(
                          Icons.store,
                          color: ColorsManger.primary,
                        ),
                        title: const Text(
                          'Branch Details',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children: state.branchSummaries.values.map((branch) {
                          return ListTile(
                            title: Text(branch.branchName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sales: ${branch.totalSales.toStringAsFixed(1)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Expenses: ${branch.totalExpenses.toStringAsFixed(1)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'EGP ${branch.netProfit.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: branch.netProfit >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
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
    final achievementPercentage = (totalSales / monthlyTarget * 100).clamp(
      0,
      999,
    );
    final isAchieved = achievementPercentage >= 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAchieved
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAchieved
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
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
                  color: isAchieved
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
  void _showExpensesBottomSheet(
    BuildContext context,
    List<ExpenseItem> expenses,
  ) {
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
                  const Icon(
                    Icons.receipt_long,
                    color: ColorsManger.primary,
                    size: 28,
                  ),
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
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
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
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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

class _BranchTile extends StatefulWidget {
  final Branch branch;
  final VoidCallback onTap;
  final int? pendingCount;
  final bool pendingLoading;
  final bool compact;

  const _BranchTile({
    required this.branch,
    required this.onTap,
    required this.pendingCount,
    required this.pendingLoading,
    required this.compact,
  });

  @override
  State<_BranchTile> createState() => _BranchTileState();
}

class _BranchTileState extends State<_BranchTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed
        ? 0.98
        : _hovered
        ? 1.02
        : 1.0;

    final glowAlpha = _pressed
        ? 0.10
        : _hovered
        ? 0.26
        : 0.16;
    final glowBlur = _hovered ? 34.0 : 26.0;
    final glowSpread = _hovered ? 2.0 : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _hovered
                      ? ColorsManger.primary.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  // Primary-colored glow (requested)
                  BoxShadow(
                    color: ColorsManger.primary.withValues(alpha: glowAlpha),
                    blurRadius: glowBlur,
                    spreadRadius: glowSpread,
                    offset: const Offset(0, 18),
                  ),
                  // Soft depth shadow
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _hovered ? 0.06 : 0.05,
                    ),
                    blurRadius: _hovered ? 24 : 18,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              padding: EdgeInsets.all(widget.compact ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: widget.compact ? 44 : 54,
                        height: widget.compact ? 44 : 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorsManger.primary.withValues(alpha: 0.20),
                              const Color(0xFF17D5E6).withValues(alpha: 0.12),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            widget.compact ? 16 : 18,
                          ),
                        ),
                        child: Icon(
                          Icons.store_rounded,
                          size: widget.compact ? 22 : 26,
                          color: ColorsManger.primary.withValues(alpha: 0.95),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.pendingLoading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if ((widget.pendingCount ?? 0) > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: widget.compact ? 8 : 10,
                                vertical: widget.compact ? 5 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: RequestStatus.pending.color.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: RequestStatus.pending.color.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Text(
                                // On mobile (compact) we still show the label for clarity.
                                '${widget.pendingCount} Pending',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: widget.compact ? 10.5 : 12,
                                  fontWeight: FontWeight.w800,
                                  color: RequestStatus.pending.color.withValues(
                                    alpha: 0.98,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: widget.compact ? 8 : 10,
                                vertical: widget.compact ? 5 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: ColorsManger.primary.withValues(
                                  alpha: 0.09,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Open',
                                style: TextStyle(
                                  fontSize: widget.compact ? 11 : 12,
                                  fontWeight: FontWeight.w800,
                                  color: ColorsManger.primary.withValues(
                                    alpha: 0.95,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: widget.compact ? 10 : 12),
                  Text(
                    widget.branch.name,
                    maxLines: widget.compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  if (!widget.compact)
                    Row(
                      children: [
                        Text(
                          'Tap to open branch',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
