import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/features/repair/logic/repair_cubit.dart';
import 'package:pharmacy/features/repair/logic/repair_state.dart';
import 'package:intl/intl.dart';
import '../../../core/themes/colors.dart';

class ViewAllBranchesRepairsScreen extends StatefulWidget {
  const ViewAllBranchesRepairsScreen({super.key});

  @override
  State<ViewAllBranchesRepairsScreen> createState() => _ViewAllBranchesRepairsScreenState();
}

class _ViewAllBranchesRepairsScreenState extends State<ViewAllBranchesRepairsScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<RepairCubit>()..fetchRepairsByMonthForBranches(month: _selectedMonth),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: ColorsManger.primaryBackground,
            appBar: AppBar(
              title: const Text(
                'All Branches Repair Reports',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: ColorsManger.primary,
              foregroundColor: Colors.white,
            ),
            body: Column(
              children: [
                // Month Selector
                _buildMonthSelector(context),

                // Repairs List
                Expanded(
                  child: BlocBuilder<RepairCubit, RepairState>(
                    builder: (context, state) {
                      if (state is FetchAllBranchesRepairsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is FetchAllBranchesRepairsError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 60, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                state.error,
                                style: const TextStyle(color: Colors.red, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      } else if (state is FetchAllBranchesRepairsSuccess) {
                        if (state.repairs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.build_circle_outlined,
                                    size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No repair reports found for this month',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<RepairCubit>().fetchRepairsByMonthForBranches(
                                  month: _selectedMonth,
                                );
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.repairs.length,
                            itemBuilder: (context, index) {
                              final repair = state.repairs[index];
                              return Card(
                                elevation: 2,
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header with Branch Name
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: ColorsManger.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.build,
                                              color: ColorsManger.primary,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  repair.deviceName,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'By ${repair.employeeName}',
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
                                      const SizedBox(height: 12),

                                      // Branch Name Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ColorsManger.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: ColorsManger.primary.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: ColorsManger.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              repair.branchName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: ColorsManger.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Notes
                                      if (repair.notes.isNotEmpty) ...[
                                        const Divider(),
                                        Text(
                                          'Notes:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          repair.notes,
                                          style: TextStyle(color: Colors.grey[800]),
                                        ),
                                      ],

                                      // Date
                                      const Divider(),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time,
                                              size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            repair.createdAt != null
                                                ? DateFormat('MMM dd, yyyy - hh:mm a')
                                                    .format(repair.createdAt!)
                                                : 'N/A',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
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

  Widget _buildMonthSelector(BuildContext context) {
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
          // Previous Month
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
              context.read<RepairCubit>().fetchRepairsByMonthForBranches(
                    month: _selectedMonth,
                  );
            },
          ),

          // Month Display
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null && picked != _selectedMonth) {
                setState(() {
                  _selectedMonth = DateTime(picked.year, picked.month);
                });
                if (!context.mounted) return;
                context.read<RepairCubit>().fetchRepairsByMonthForBranches(
                      month: _selectedMonth,
                    );
              }
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
                  const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Next Month
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _selectedMonth.isBefore(
              DateTime(DateTime.now().year, DateTime.now().month ),
            )
                ? () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      );
                    });
                    context.read<RepairCubit>().fetchRepairsByMonthForBranches(
                          month: _selectedMonth,
                        );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

