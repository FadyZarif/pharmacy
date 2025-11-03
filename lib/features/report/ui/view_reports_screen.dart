import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/widgets/profile_circle.dart';
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

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ViewReportsCubit>()..fetchDailyReports(_formattedDate),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: ColorsManger.primaryBackground,
            appBar: AppBar(
              title: const Text('Daily Reports'),
              centerTitle: true,
              backgroundColor: ColorsManger.primary,
              foregroundColor: Colors.white,
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
                        return ListView.builder(
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
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManger.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month, color: Colors.white),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _selectDate(context),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final cubit = context.read<ViewReportsCubit>();

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
      cubit.fetchDailyReports(_formattedDate);
    }
  }
}

