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

import '../../../core/themes/colors.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({super.key});

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  late ViewReportsCubit _viewReportsCubit;
  late ViewReportsCubit _monthlySummaryCubit;

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _viewReportsCubit = getIt<ViewReportsCubit>()..fetchDailyReports(_formattedDate);
    _monthlySummaryCubit = getIt<ViewReportsCubit>();
  }

  @override
  void dispose() {
    _viewReportsCubit.close();
    _monthlySummaryCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _viewReportsCubit),
        BlocProvider.value(value: _monthlySummaryCubit),
      ],
      child: BlocListener<ViewReportsCubit, ViewReportsState>(
        bloc: _monthlySummaryCubit,
        listenWhen: (previous, current) =>
            current is MonthlySummaryLoading ||
            current is MonthlySummaryLoaded ||
            current is MonthlySummaryError,
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
                actions: currentUser.isManagement? [
                  IconButton(
                    icon: const Icon(Icons.calendar_view_month, color: Colors.white),
                    tooltip: 'Monthly Summary',
                    onPressed: () => _monthlySummaryCubit.fetchMonthlySummary(_selectedDate),
                  ),
                ]:null,
              ),
              body: Column(
              children: [
                _buildDateSelector(context),
                Expanded(
                  child: BlocBuilder<ViewReportsCubit, ViewReportsState>(
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
                                  context.read<ViewReportsCubit>().fetchDailyReports(_formattedDate);
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
                                padding: const EdgeInsets.all(16),
                                itemCount: state.reports.length,
                                itemBuilder: (context, index) {
                                  final report = state.reports[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    color: Colors.white,
                                    child: ListTile(
                                      leading: ProfileCircle(
                                        photoUrl: report.employeePhoto,
                                        size: 26,
                                      ),
                                      title: Text('${report.shiftType.name} Shift'),
                                      subtitle: Text(report.employeeName),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'EGP ${report.drawerAmount}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward_ios),
                                        ],
                                      ),
                                      onTap: () {
                                        final cubit = context.read<ViewReportsCubit>();
                                        final dateStr = _formattedDate;

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditShiftReportScreen(
                                              report: report,
                                              date: dateStr,
                                            ),
                                          ),
                                        ).then((_) {
                                          // Refresh after editing
                                          cubit.fetchDailyReports(dateStr);
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
      padding: const EdgeInsets.all(16),
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
              context.read<ViewReportsCubit>().fetchDailyReports(_formattedDate);
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
              context.read<ViewReportsCubit>().fetchDailyReports(_formattedDate);

            }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(List<dynamic> reports) {
    // حساب مجموع drawerAmount
    final totalDrawerAmount = reports.fold<double>(
      0.0,
      (sum, report) => sum + (report.drawerAmount ?? 0.0),
    );

    // حساب مجموع مصاريف تبديل الأدوية
    final totalMedicinesExpenses = reports.fold<double>(
      0.0,
      (sum, report) {
        final medicinesExpenses = (report.expenses as List<ExpenseItem>).where(
          (expense) => expense.type == ExpenseType.medicines,
        ).fold<double>(0.0, (expSum, expense) => expSum + expense.amount);
        return sum + medicinesExpenses;
      },
    );

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Medicines Expenses',
              amount: totalMedicinesExpenses,
              icon: Icons.medication,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Sales',
              amount: totalDrawerAmount,
              icon: Icons.attach_money,
              color: Colors.green,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'EGP ${amount.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
      _viewReportsCubit.fetchDailyReports(_formattedDate);
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Total Sales Card
            _buildMonthlySummaryCard(
              title: 'Total Sales',
              amount: state.totalSales,
              icon: Icons.attach_money,
              color: Colors.green,
            ),
            const SizedBox(height: 16),

            // Medicines Expenses Card
            _buildMonthlySummaryCard(
              title: 'Medicines Expenses',
              amount: state.totalMedicinesExpenses,
              icon: Icons.medication,
              color: Colors.orange,
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
    );
  }

  Widget _buildMonthlySummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
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
                  'EGP ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

