import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/features/repair/logic/repair_cubit.dart';
import 'package:pharmacy/features/repair/logic/repair_state.dart';
import 'package:intl/intl.dart';

import '../../../core/helpers/constants.dart';
import '../../../core/themes/colors.dart';

class ViewRepairsScreen extends StatefulWidget {
  const ViewRepairsScreen({super.key});

  @override
  State<ViewRepairsScreen> createState() => _ViewRepairsScreenState();
}

class _ViewRepairsScreenState extends State<ViewRepairsScreen> {
  DateTime _selectedDate = DateTime.now();


  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<RepairCubit>()..fetchRepairsByBranchAndDate(
            branchId: currentUser.currentBranch.id,
            date: _selectedDate,
          ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: ColorsManger.primaryBackground,
            appBar: AppBar(
              title: Text('Repair Reports [${currentUser.currentBranch.name}]',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
              backgroundColor: ColorsManger.primary,
              foregroundColor: Colors.white,
            ),
            body: Column(
              children: [
                // Date Selector
                _buildDateSelector(context),

                // Repairs List
                Expanded(
                  child: BlocBuilder<RepairCubit, RepairState>(
                    builder: (context, state) {
                      if (state is FetchRepairsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is FetchRepairsError) {
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
                      } else if (state is FetchRepairsSuccess) {
                        if (state.repairs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.build_circle_outlined,
                                    size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No repair reports found for this date',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<RepairCubit>().fetchRepairsByBranchAndDate(
                                  branchId: currentUser.currentBranch.id,
                                  date: _selectedDate,
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
                                      // Header
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
              context.read<RepairCubit>().fetchRepairsByBranchAndDate(
                    branchId: currentUser.currentBranch.id,
                    date: _selectedDate,
                  );
            },
          ),

          // Date Display
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
                if (!context.mounted) return;
                context.read<RepairCubit>().fetchRepairsByBranchAndDate(
                      branchId: currentUser.currentBranch.id,
                      date: _selectedDate,
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
                    context.read<RepairCubit>().fetchRepairsByBranchAndDate(
                          branchId: currentUser.currentBranch.id,
                          date: _selectedDate,
                        );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

