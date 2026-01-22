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
                content: Text(_isCollected
                    ? 'Net profit marked as collected ✓'
                    : 'Net profit marked as not collected'),
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
            return Scaffold(
              backgroundColor: ColorsManger.primaryBackground,
              appBar: AppBar(
                title: Text('Daily Reports [${currentUser.currentBranch.name}]',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                centerTitle: true,
                backgroundColor: ColorsManger.primary,
                foregroundColor: Colors.white,
                actions: (currentUser.isManagement || currentUser.uid=='7DUwUuQ0rIUUb94NCK2vdnrZCLo1')? [
                  IconButton(
                    icon: const Icon(Icons.calendar_view_month, color: Colors.white),
                    tooltip: 'Monthly Summary',
                    onPressed: () => _cubit.fetchMonthlySummary(_selectedDate),
                  ),
                ]:null,
              ),
              body: Column(
              children: [
                _buildDateSelector(context),
                Expanded(
                  child: BlocBuilder<ViewReportsCubit, ViewReportsState>(
                    buildWhen: (previous, current) =>
                        current is ViewReportsLoading ||
                        current is ViewReportsLoaded ||
                        current is ViewReportsEmpty ||
                        current is ViewReportsError,
                    builder: (context, state) {
                      if (state is ViewReportsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is ViewReportsError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 60, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(state.message),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  _cubit.fetchDailyReports(_formattedDate);
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      } else if (state is ViewReportsEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No reports for this date'),
                            ],
                          ),
                        );
                      } else if (state is ViewReportsLoaded) {
                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(9),
                                itemCount: state.reports.length,
                                itemBuilder: (context, index) {
                                  final report = state.reports[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    color: Colors.white,
                                    child: ListTile(
                                      leading: ProfileCircle(
                                        photoUrl: report.employeePhoto,
                                        size: 26,
                                      ),
                                      title: Text('${report.shiftType.name} Shift',style: TextStyle(fontSize: 15),),
                                      subtitle: Text(report.employeeName),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'EGP ${report.drawerAmount}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                'EGP ${report.netAmount}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward_ios),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditShiftReportScreen(
                                              report: report,
                                              date: _formattedDate,
                                            ),
                                          ),
                                        ).then((_) {
                                          // Refresh after editing
                                          _cubit.fetchDailyReports(_formattedDate);
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            _buildSummarySection(state.reports),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
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
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColorsManger.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Day
          IconButton(
            icon: const Icon(Icons.chevron_left,color: Colors.white,),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Next Day
          IconButton(
            icon: const Icon(Icons.chevron_right,color: Colors.white,),
            onPressed: _selectedDate.isBefore(
              DateTime.now().subtract(const Duration(days: 1)),
            )
                ? () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
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

  Widget _buildSummarySection(List<dynamic> reports) {
    // حساب مجموع drawerAmount (Total Sales)
    final totalSales = reports.fold<double>(
      0.0,
      (sum, report) => sum + (report.drawerAmount ?? 0.0),
    );

    // حساب مجموع كل المصاريف (Total Expenses)
    final totalExpenses = reports.fold<double>(
      0.0,
      (sum, report) => sum + (report as ShiftReportModel).totalExpenses,
    );

    // جمع كل المصاريف من جميع التقارير
    final allExpenses = reports.expand((report) => (report as ShiftReportModel).expenses).toList();

    // حساب صافي الربح (Net Profit)
    final netProfit = totalSales - totalExpenses;

    // حساب مجموع مصاريف تبديل الأدوية (Medicines Expenses)
    final totalMedicinesExpenses = reports.fold<double>(
      0.0,
      (sum, report) {
        final medicinesExpenses = (report as ShiftReportModel).medicineExpenses;
        return sum + medicinesExpenses;
      },
    );

    // حساب مجموع مصاريف الدفع الإلكتروني (Electronic Payment Expenses)
    final totalElectronicPaymentExpenses = reports.fold<double>(
      0.0,
      (sum, report) {
        final electronicExpenses = (report as ShiftReportModel).expenses
            .where((expense) => expense.type == ExpenseType.electronicPayment)
            .fold<double>(0.0, (total, expense) => total + expense.amount);
        return sum + electronicExpenses;
      },
    );

    // حساب مجموع الزيادة (Total Surplus)
    final totalSurplus = reports.fold<double>(
      0.0,
      (sum, report) {
        final shiftReport = report as ShiftReportModel;
        if (shiftReport.computerDifferenceType == ComputerDifferenceType.excess) {
          return sum + shiftReport.computerDifference;
        }
        return sum;
      },
    );

    // حساب مجموع العجز (Total Deficit)
    final totalDeficit = reports.fold<double>(
      0.0,
      (sum, report) {
        final shiftReport = report as ShiftReportModel;
        if (shiftReport.computerDifferenceType == ComputerDifferenceType.shortage) {
          return sum + shiftReport.computerDifference;
        }
        return sum;
      },
    );

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Row: Total Sales & Total Expenses
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Sales',
                  amount: totalSales,
                  icon: Icons.attach_money,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Expenses',
                  amount: totalExpenses,
                  icon: Icons.money_off,
                  color: Colors.orange,
                  onTap: () => _showExpensesBottomSheet(context, allExpenses),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Second Row: Net Profit (Full Width)
          _buildSummaryCard(
            title: 'Net Profit',
            amount: netProfit,
            icon: netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
            color: netProfit >= 0 ? Colors.green : Colors.red,
            isLarge: false,
            isCollected: _isCollected,
            onTap:( currentUser.isAdmin || currentUser.uid == '7DUwUuQ0rIUUb94NCK2vdnrZCLo1')
                ? () => _showCollectionConfirmationDialog(context)
                : null,
          ),
          const SizedBox(height: 8),

          // Third Row: Medicines & Electronic Payment Expenses
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Medicines Exp.',
                  amount: totalMedicinesExpenses,
                  icon: Icons.medication,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Electronic Pay.',
                  amount: totalElectronicPaymentExpenses,
                  icon: Icons.credit_card,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fourth Row: Excess & Shortage
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Excess',
                  amount: totalSurplus,
                  icon: Icons.add_circle,
                  color: Colors.lightGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Shortage',
                  amount: totalDeficit,
                  icon: Icons.remove_circle,
                  color: Colors.redAccent,
                ),
              ),
            ],
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
    bool isLarge = false,
    bool? isCollected,
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      padding: EdgeInsets.all(isLarge ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: isLarge ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: isLarge ? 24 : 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isLarge ? 14 : 12,
                    fontWeight: isLarge ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Show collection status if applicable
              if (isCollected != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCollected ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCollected ? Icons.check_circle : Icons.pending,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCollected ? 'Collected' : 'Pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'EGP ${amount.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: isLarge ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );

    // If onTap is provided, wrap with InkWell
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    }

    return cardContent;
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                icon: state.netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
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
            child: Icon(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
}

