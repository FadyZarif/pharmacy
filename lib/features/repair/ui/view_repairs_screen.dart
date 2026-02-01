import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/features/repair/logic/repair_cubit.dart';
import 'package:pharmacy/features/repair/logic/repair_state.dart';
import 'package:pharmacy/features/repair/ui/view_all_branches_repairs_screen.dart';
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
    return BlocProvider.value(
      value:  getIt<RepairCubit>()..fetchRepairsByBranchAndDate(
            branchId: currentUser.currentBranch.id,
            date: _selectedDate,
          ),
      child: Builder(
        builder: (context) {
          final topPad = MediaQuery.of(context).padding.top;
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
                    'Repair Reports · ${currentUser.currentBranch.name}',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.80),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  actions: [
                    if (currentUser.branches.length > 1)
                      IconButton(
                        icon: const Icon(Icons.grid_view, color: ColorsManger.primary),
                        tooltip: 'View All Branches',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ViewAllBranchesRepairsScreen(),
                            ),
                          );
                        },
                      ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
            body: Stack(
              children: [
                const _RepairsBackground(),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    topPad + kToolbarHeight + 12,
                    16,
                    0,
                  ),
                  child: Column(
                    children: [
                      _buildDateSelector(context),
                      const SizedBox(height: 12),
                      Expanded(
                        child: BlocBuilder<RepairCubit, RepairState>(
                    builder: (context, state) {
                      if (state is FetchRepairsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: ColorsManger.primary),
                        );
                      } else if (state is FetchRepairsError) {
                        return Center(
                          child: _PanelCard(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                                const SizedBox(height: 12),
                                Text(
                                  state.error,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (state is FetchRepairsSuccess) {
                        if (state.repairs.isEmpty) {
                          return Center(
                            child: _PanelCard(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.build_circle_outlined,
                                    size: 56,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No repair reports found for this date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey[650],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            getIt<RepairCubit>().fetchRepairsByBranchAndDate(
                                  branchId: currentUser.currentBranch.id,
                                  date: _selectedDate,
                              forceUpdate: true,
                                );
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                            itemCount: state.repairs.length,
                            itemBuilder: (context, index) {
                              final repair = state.repairs[index];
                              return _PanelCard(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                Text(
                                                  'By ${repair.employeeName}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black.withValues(alpha: 0.55),
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
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black.withValues(alpha: 0.65),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          repair.notes,
                                          style: TextStyle(
                                            color: Colors.black.withValues(alpha: 0.72),
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black.withValues(alpha: 0.55),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return _PanelCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Day
          IconButton(
            icon: const Icon(Icons.chevron_left, color: ColorsManger.primary),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              context.read<RepairCubit>().fetchRepairsByBranchAndDate(
                    branchId: currentUser.currentBranch.id,
                    date: _selectedDate,
                forceUpdate: true,
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
                  forceUpdate: true,
                    );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: ColorsManger.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorsManger.primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: ColorsManger.primary, size: 18),
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
              color: _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                  ? ColorsManger.primary
                  : Colors.grey,
            ),
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
                      forceUpdate: true,
                        );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _RepairsBackground extends StatelessWidget {
  const _RepairsBackground();

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
  final EdgeInsetsGeometry margin;

  const _PanelCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
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

