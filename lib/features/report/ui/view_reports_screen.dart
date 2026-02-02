import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/widgets/profile_circle.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/view_reports_cubit.dart';
import 'package:pharmacy/features/report/logic/view_reports_state.dart';
import 'package:pharmacy/features/report/ui/edit_shift_report_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/themes/colors.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({super.key});

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  late ViewReportsCubit _cubit;
  bool _isCollected = false;

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);
  final _egp = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ViewReportsCubit>()
      ..fetchDailyReports(_formattedDate)
      ..fetchCollectionStatus(_formattedDate);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ViewReportsCubit, ViewReportsState>(
        listenWhen: (previous, current) =>
            current is MonthlySummaryLoading ||
            current is MonthlySummaryLoaded ||
            current is MonthlySummaryError ||
            current is CollectionStatusLoading ||
            current is CollectionStatusLoaded ||
            current is CollectionStatusUpdated ||
            current is CollectionStatusError,
        listener: (context, state) {
          if (state is MonthlySummaryLoading) {
            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(color: ColorsManger.primary),
              ),
            );
          } else if (state is MonthlySummaryLoaded) {
            // Close loading dialog
            Navigator.pop(context);

            // Show summary dialog
            showDialog(
              context: context,
              builder: (context) => _buildMonthlySummaryDialog(state),
            );
          } else if (state is MonthlySummaryError) {
            // Close loading dialog
            Navigator.pop(context);

            // Show error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading monthly data: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CollectionStatusLoaded) {
            setState(() {
              _isCollected = state.isCollected;
            });
          } else if (state is CollectionStatusUpdated) {
            setState(() {
              _isCollected = state.isCollected;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isCollected
                      ? 'Net profit marked as collected ✓'
                      : 'Net profit marked as not collected',
                ),
                backgroundColor: _isCollected ? Colors.green : Colors.orange,
              ),
            );
          } else if (state is CollectionStatusError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Builder(
          builder: (context) {
            final topPad = MediaQuery.of(context).padding.top;
            final bottomPad = MediaQuery.of(context).padding.bottom;
            // This screen is hosted inside `EmployeeLayout` which uses `extendBody: true`
            // with a glass bottom navigation (height: 66 + outer padding: 14). Add enough
            // bottom padding so content won't be covered on mobile.
            const glassNavHeight = 66.0;
            const glassNavOuterPadding = 14.0;
            final bottomGap =
                bottomPad + glassNavHeight + glassNavOuterPadding + 10;
            return Scaffold(
              backgroundColor: ColorsManger.primaryBackground,
              extendBodyBehindAppBar: true,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.56),
                    border: Border(
                      bottom: BorderSide(
                        color: ColorsManger.primary.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                  ),
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    title: Text(
                      'Daily Reports · ${currentUser.currentBranch.name}',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.80),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.calendar_view_month,
                          color: ColorsManger.primary,
                        ),
                        tooltip: 'Monthly Summary',
                        onPressed: () =>
                            _cubit.fetchMonthlySummary(_selectedDate),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
              body: Stack(
                children: [
                  // Background
                  const _ReportBackground(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      topPad + kToolbarHeight + 12,
                      16,
                      bottomGap,
                    ),
                    child: Column(
                      children: [
                        _buildDateSelector(context),
                        const SizedBox(height: 12),
                        Expanded(
                          child: BlocBuilder<ViewReportsCubit, ViewReportsState>(
                            buildWhen: (previous, current) =>
                                current is ViewReportsLoading ||
                                current is ViewReportsLoaded ||
                                current is ViewReportsEmpty ||
                                current is ViewReportsError,
                            builder: (context, state) {
                              if (state is ViewReportsLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: ColorsManger.primary,
                                  ),
                                );
                              } else if (state is ViewReportsError) {
                                return Center(
                                  child: Container(
                                    margin: const EdgeInsets.all(16),
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          size: 56,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          state.message,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _cubit.fetchDailyReports(
                                                _formattedDate,
                                              ),
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Retry'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                ColorsManger.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else if (state is ViewReportsEmpty) {
                                return Center(
                                  child: Container(
                                    margin: const EdgeInsets.all(16),
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.withValues(
                                          alpha: 0.16,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          size: 56,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'No reports for this date',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else if (state is ViewReportsLoaded) {
                                final isCompact =
                                    MediaQuery.sizeOf(context).width < 650;

                                // On compact/mobile, dock Totals as a fixed card above the glass bottom nav
                                // and add bottom padding to the list so it doesn't get covered.
                                if (isCompact) {
                                  return LayoutBuilder(
                                    builder: (context, c) {
                                      final dockHeight =
                                          _estimateTotalsDockHeight(
                                            width: c.maxWidth,
                                          );
                                      return Stack(
                                        children: [
                                          ListView.separated(
                                            padding: EdgeInsets.only(
                                              bottom: dockHeight + 12,
                                            ),
                                            itemCount: state.reports.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 8),
                                            itemBuilder: (context, index) {
                                              final report =
                                                  state.reports[index];
                                              return _ShiftReportTile(
                                                report: report,
                                                egp: _egp,
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          EditShiftReportScreen(
                                                            report: report,
                                                            date:
                                                                _formattedDate,
                                                          ),
                                                    ),
                                                  ).then((_) {
                                                    _cubit.fetchDailyReports(
                                                      _formattedDate,
                                                    );
                                                  });
                                                },
                                              );
                                            },
                                          ),
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: _TotalsDockCard(
                                              reports: state.reports,
                                              egp: _egp,
                                              isCollected: _isCollected,
                                              onToggleCollect:
                                                  (currentUser.isAdmin ||
                                                      currentUser.uid ==
                                                          '7DUwUuQ0rIUUb94NCK2vdnrZCLo1')
                                                  ? () =>
                                                        _showCollectionConfirmationDialog(
                                                          context,
                                                        )
                                                  : null,
                                              onShowExpenses: () =>
                                                  _showExpensesBottomSheet(
                                                    context,
                                                    state.reports
                                                        .expand(
                                                          (r) => r.expenses,
                                                        )
                                                        .toList(),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }

                                // Wider layouts: keep totals at the bottom (still as a card) without overlay.
                                return Column(
                                  children: [
                                    Expanded(
                                      child: ListView.separated(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        itemCount: state.reports.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final report = state.reports[index];
                                          return _ShiftReportTile(
                                            report: report,
                                            egp: _egp,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EditShiftReportScreen(
                                                        report: report,
                                                        date: _formattedDate,
                                                      ),
                                                ),
                                              ).then((_) {
                                                _cubit.fetchDailyReports(
                                                  _formattedDate,
                                                );
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _TotalsDockCard(
                                      reports: state.reports,
                                      egp: _egp,
                                      isCollected: _isCollected,
                                      onToggleCollect:
                                          (currentUser.isAdmin ||
                                              currentUser.uid ==
                                                  '7DUwUuQ0rIUUb94NCK2vdnrZCLo1')
                                          ? () =>
                                                _showCollectionConfirmationDialog(
                                                  context,
                                                )
                                          : null,
                                      onShowExpenses: () =>
                                          _showExpensesBottomSheet(
                                            context,
                                            state.reports
                                                .expand((r) => r.expenses)
                                                .toList(),
                                          ),
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return _PanelCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Day
          IconButton(
            icon: const Icon(Icons.chevron_left, color: ColorsManger.primary),
            tooltip: 'Previous day',
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              context.read<ViewReportsCubit>()
                ..fetchDailyReports(_formattedDate)
                ..fetchCollectionStatus(_formattedDate);
            },
          ),

          // Date Display
          InkWell(
            onTap: () async {
              _selectDate(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: ColorsManger.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorsManger.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: ColorsManger.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Next Day
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color:
                  _selectedDate.isBefore(
                    DateTime.now().subtract(const Duration(days: 1)),
                  )
                  ? ColorsManger.primary
                  : Colors.grey,
            ),
            tooltip: 'Next day',
            onPressed:
                _selectedDate.isBefore(
                  DateTime.now().subtract(const Duration(days: 1)),
                )
                ? () {
                    setState(() {
                      _selectedDate = _selectedDate.add(
                        const Duration(days: 1),
                      );
                    });
                    context.read<ViewReportsCubit>()
                      ..fetchDailyReports(_formattedDate)
                      ..fetchCollectionStatus(_formattedDate);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      helpText: 'Select Date',
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
      });
      _cubit
        ..fetchDailyReports(_formattedDate)
        ..fetchCollectionStatus(_formattedDate);
    }
  }

  Widget _buildMonthlySummaryDialog(MonthlySummaryLoaded state) {
    final monthName = DateFormat('MMMM yyyy').format(_selectedDate);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: ColorsManger.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          monthName,
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
              // const SizedBox(height: 24),
              // const Divider(),
              const SizedBox(height: 24),

              // Total Sales Card
              _buildMonthlySummaryCard(
                title: 'Total Sales',
                amount: state.totalSales,
                icon: Icons.attach_money,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),

              // Target Achievement Card (if target is set)
              if (state.monthlyTarget != null) ...[
                _buildTargetAchievementCard(
                  totalSales: state.totalSales,
                  monthlyTarget: state.monthlyTarget!,
                ),
                const SizedBox(height: 16),
              ],
              if (currentUser.isManagement ||
                  currentUser.uid == '7DUwUuQ0rIUUb94NCK2vdnrZCLo1') ...[
                // Total Expenses Card (Clickable)
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // Close the monthly summary dialog
                    _showExpensesBottomSheet(context, state.allExpenses);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMonthlySummaryCard(
                    title: 'Total Expenses',
                    amount: state.totalExpenses,
                    icon: Icons.money_off,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),

                // Net Profit Card
                _buildMonthlySummaryCard(
                  title: 'Net Profit',
                  amount: state.netProfit,
                  icon: state.netProfit >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: state.netProfit >= 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),

                // Medicines Expenses Card
                _buildMonthlySummaryCard(
                  title: 'Medicines Expenses',
                  amount: state.totalMedicinesExpenses,
                  icon: Icons.medication,
                  color: Colors.purple,
                ),
                const SizedBox(height: 16),

                // Electronic Payment Expenses Card
                _buildMonthlySummaryCard(
                  title: 'Electronic Payment Expenses',
                  amount: state.totalElectronicPaymentExpenses,
                  icon: Icons.credit_card,
                  color: Colors.teal,
                ),
                const SizedBox(height: 16),

                // Excess and Shortage Row
                _buildMonthlySummaryCard(
                  title: 'Total Excess',
                  amount: state.totalSurplus,
                  icon: Icons.add_circle,
                  color: Colors.lightGreen,
                ),
                const SizedBox(height: 16),
                _buildMonthlySummaryCard(
                  title: 'Total Shortage',
                  amount: state.totalDeficit,
                  icon: Icons.remove_circle,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),

                // Vault Amount Card (Uncollected Profits)
                _buildMonthlySummaryCard(
                  title: 'Vault Amount (Uncollected)',
                  amount: state.vaultAmount,
                  icon: Icons.account_balance_wallet,
                  color: Colors.amber,
                  subtitle: 'Total net profit not yet collected',
                ),

                const SizedBox(height: 24),

                // Set Monthly Target Button (Admin only)
                if (currentUser.isAdmin) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        _showSetMonthlyTargetDialog(
                          context,
                          _selectedDate,
                          state.monthlyTarget,
                        );
                      },
                      icon: const Icon(Icons.flag),
                      label: Text(
                        state.monthlyTarget == null
                            ? 'Set Monthly Target'
                            : 'Update Monthly Target',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorsManger.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: ColorsManger.primary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
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
                      'Target Achievement',
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

  Widget _buildMonthlySummaryCard({
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
            child: Icon(Icons.receipt, color: ColorsManger.primary, size: 24),
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
                style: TextStyle(
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

  /// عرض dialog للتأكيد على تحديث حالة التحصيل
  Future<void> _showCollectionConfirmationDialog(BuildContext context) async {
    final willCollect = !_isCollected;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              willCollect ? Icons.check_circle : Icons.pending,
              color: willCollect ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            const Text('Confirm Collection'),
          ],
        ),
        content: Text(
          willCollect
              ? 'Are you sure you want to mark this net profit as collected?'
              : 'Are you sure you want to mark this net profit as pending?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: willCollect ? Colors.green : Colors.orange,
            ),
            child: Text(
              willCollect ? 'Mark as Collected' : 'Mark as Pending',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _cubit.toggleCollectionStatus(_formattedDate, _isCollected);
    }
  }

  /// عرض dialog لتحديد الهدف الشهري
  Future<void> _showSetMonthlyTargetDialog(
    BuildContext context,
    DateTime selectedDate,
    double? currentTarget,
  ) async {
    final TextEditingController targetController = TextEditingController(
      text: currentTarget?.toStringAsFixed(0) ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.flag, color: ColorsManger.primary),
            const SizedBox(width: 12),
            const Text('Set Monthly Target'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Month: ${DateFormat('MMMM yyyy').format(selectedDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monthly Target (EGP)',
                hintText: 'Enter target amount',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManger.primary,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final targetText = targetController.text.trim();
      if (targetText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid target amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final target = double.tryParse(targetText);
      if (target == null || target <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid positive number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: ColorsManger.primary),
        ),
      );

      await _cubit.setMonthlyTarget(selectedDate, target);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monthly target updated successfully ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    targetController.dispose();
  }
}

class _ReportBackground extends StatelessWidget {
  const _ReportBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorsManger.primary.withValues(alpha: 0.08),
            ColorsManger.primaryBackground,
            ColorsManger.primaryBackground,
          ],
        ),
      ),
      child: Stack(
        children: const [
          _GlowBlob(
            alignment: Alignment(-1.05, -0.80),
            radius: 160,
            color: Color(0x1A00B4D8),
          ),
          _GlowBlob(
            alignment: Alignment(1.10, -0.25),
            radius: 200,
            color: Color(0x14008AC7),
          ),
          _GlowBlob(
            alignment: Alignment(0.20, 1.10),
            radius: 260,
            color: Color(0x1200B4D8),
          ),
        ],
      ),
    );
  }
}

List<BoxShadow> _panelShadow() => [
  BoxShadow(
    color: ColorsManger.primary.withValues(alpha: 0.14),
    blurRadius: 22,
    offset: const Offset(0, 12),
  ),
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 18,
    offset: const Offset(0, 10),
  ),
];

class _PanelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _PanelCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: _panelShadow(),
      ),
      child: child,
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Alignment alignment;
  final double radius;
  final Color color;

  const _GlowBlob({
    required this.alignment,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.85),
              blurRadius: radius,
              spreadRadius: radius * 0.25,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftReportTile extends StatelessWidget {
  final ShiftReportModel report;
  final NumberFormat egp;
  final VoidCallback onTap;

  const _ShiftReportTile({
    required this.report,
    required this.egp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final netColor = report.netAmount >= 0 ? Colors.green : Colors.red;
    final isNarrow = MediaQuery.sizeOf(context).width < 380;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: ColorsManger.primary.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            ProfileCircle(photoUrl: report.employeePhoto, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: ColorsManger.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: ColorsManger.primary.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          report.shiftNameAr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ColorsManger.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          report.employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Keep pills side-by-side even on small phones by shrinking text/padding.
                  Row(
                    children: [
                      Expanded(
                        child: _AmountPill(
                          label: 'Sales',
                          value: egp.format(report.drawerAmount),
                          color: Colors.blue,
                          compact: isNarrow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AmountPill(
                          label: 'Net',
                          value: egp.format(report.netAmount),
                          color: netColor,
                          compact: isNarrow,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

class _AmountPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool compact;

  const _AmountPill({
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label · ',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.92),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSummaryCard({
  required NumberFormat egp,
  required String title,
  required double amount,
  required IconData icon,
  required Color color,
  bool? isCollected,
  VoidCallback? onTap,
}) {
  final amountText = egp.format(amount);

  Widget statusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCollected == true ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCollected == true ? Icons.check_circle : Icons.pending,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isCollected == true ? 'Collected' : 'Pending',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  final cardContent = LayoutBuilder(
    builder: (context, c) {
      final isNarrow = c.maxWidth < 230;
      final amountFontSize = isNarrow ? 16.0 : 18.0;

      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.28), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCollected != null && !isNarrow) ...[
                  const SizedBox(width: 6),
                  statusPill(),
                ],
              ],
            ),
            if (isCollected != null && isNarrow) ...[
              const SizedBox(height: 8),
              statusPill(),
            ],
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amountText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  if (onTap != null) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: cardContent,
    );
  }
  return cardContent;
}

double _estimateTotalsDockHeight({required double width}) {
  // Matches the columns logic used inside the totals grid.
  final columns = width >= 980
      ? 3
      : (width >= 640 ? 2 : (width >= 360 ? 2 : 1));
  const itemsCount = 7;
  const spacing = 10.0;
  // The dock card has: title row + spacing + grid rows + padding.
  const headerHeight = 44.0;
  const outerPadding = 14.0 * 2;
  const cardHeight = 92.0;
  final rows = (itemsCount / columns).ceil().clamp(1, 99);
  final gridHeight = (rows * cardHeight) + ((rows - 1) * spacing);
  return headerHeight + 10 + gridHeight + outerPadding;
}

class _TotalsDockCard extends StatelessWidget {
  final List<ShiftReportModel> reports;
  final NumberFormat egp;
  final bool isCollected;
  final VoidCallback? onToggleCollect;
  final VoidCallback onShowExpenses;

  const _TotalsDockCard({
    required this.reports,
    required this.egp,
    required this.isCollected,
    required this.onToggleCollect,
    required this.onShowExpenses,
  });

  @override
  Widget build(BuildContext context) {
    // حساب مجموع drawerAmount (Total Sales)
    final totalSales = reports.fold<double>(
      0.0,
      (sum, report) => sum + report.drawerAmount,
    );

    // حساب مجموع كل المصاريف (Total Expenses)
    final totalExpenses = reports.fold<double>(
      0.0,
      (sum, report) => sum + report.totalExpenses,
    );

    // حساب صافي الربح (Net Profit)
    final netProfit = totalSales - totalExpenses;

    // حساب مجموع مصاريف تبديل الأدوية (Medicines Expenses)
    final totalMedicinesExpenses = reports.fold<double>(0.0, (sum, report) {
      final medicinesExpenses = report.medicineExpenses;
      return sum + medicinesExpenses;
    });

    // حساب مجموع مصاريف الدفع الإلكتروني (Electronic Payment Expenses)
    final totalElectronicPaymentExpenses = reports.fold<double>(0.0, (
      sum,
      report,
    ) {
      final electronicExpenses = report.expenses
          .where((expense) => expense.type == ExpenseType.electronicPayment)
          .fold<double>(0.0, (total, expense) => total + expense.amount);
      return sum + electronicExpenses;
    });

    // حساب مجموع الزيادة (Total Surplus)
    final totalSurplus = reports.fold<double>(0.0, (sum, report) {
      if (report.computerDifferenceType == ComputerDifferenceType.excess) {
        return sum + report.computerDifference;
      }
      return sum;
    });

    // حساب مجموع العجز (Total Deficit)
    final totalDeficit = reports.fold<double>(0.0, (sum, report) {
      if (report.computerDifferenceType == ComputerDifferenceType.shortage) {
        return sum + report.computerDifference;
      }
      return sum;
    });

    return _PanelCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth;
          final columns = width >= 980
              ? 3
              : (width >= 640 ? 2 : (width >= 360 ? 2 : 1));
          const spacing = 10.0;
          final cardWidth = (width - (spacing * (columns - 1))) / columns;
          const cardHeight = 92.0;

          Widget titleRow() {
            return Row(
              children: [
                Text(
                  'Totals',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withValues(alpha: 0.78),
                  ),
                ),
                const Spacer(),
                if (onToggleCollect != null)
                  TextButton.icon(
                    onPressed: onToggleCollect,
                    style: TextButton.styleFrom(
                      foregroundColor: isCollected
                          ? Colors.green
                          : ColorsManger.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    icon: Icon(
                      isCollected ? Icons.check_circle : Icons.pending,
                      size: 18,
                    ),
                    label: Text(
                      isCollected ? 'Collected' : 'Pending',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            );
          }

          final items = <Widget>[
            _buildSummaryCard(
              egp: egp,
              title: 'Total Sales',
              amount: totalSales,
              icon: Icons.attach_money,
              color: Colors.blue,
            ),
            _buildSummaryCard(
              egp: egp,
              title: 'Total Expenses',
              amount: totalExpenses,
              icon: Icons.money_off,
              color: Colors.orange,
              onTap: onShowExpenses,
            ),
            _buildSummaryCard(
              egp: egp,
              title: 'Net Profit',
              amount: netProfit,
              icon: netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
              color: netProfit >= 0 ? Colors.green : Colors.red,
              // Avoid extra vertical content in small fixed-height cards:
              // collection state is already shown in the Totals header button.
              isCollected: null,
              onTap: onToggleCollect,
            ),
            _buildSummaryCard(
              egp: egp,
              title: 'Medicines Exp.',
              amount: totalMedicinesExpenses,
              icon: Icons.medication,
              color: Colors.purple,
            ),
            _buildSummaryCard(
              egp: egp,
              title: 'Electronic Pay.',
              amount: totalElectronicPaymentExpenses,
              icon: Icons.credit_card,
              color: Colors.teal,
            ),
            _buildSummaryCard(
              egp: egp,
              title: 'Total Excess',
              amount: totalSurplus,
              icon: Icons.add_circle,
              color: Colors.lightGreen,
            ),
            _buildSummaryCard(
              egp: egp,
              title: 'Total Shortage',
              amount: totalDeficit,
              icon: Icons.remove_circle,
              color: Colors.redAccent,
            ),
          ];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              titleRow(),
              const SizedBox(height: 10),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final w in items)
                    SizedBox(width: cardWidth, height: cardHeight, child: w),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
