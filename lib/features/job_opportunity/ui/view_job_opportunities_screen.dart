import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/job_opportunity/logic/job_opportunity_cubit.dart';
import 'package:pharmacy/features/job_opportunity/ui/add_job_opportunity_screen.dart';
import 'package:pharmacy/features/job_opportunity/ui/widgets/job_opportunity_card.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../../../core/helpers/constants.dart';

class ViewJobOpportunitiesScreen extends StatefulWidget {
  const ViewJobOpportunitiesScreen({super.key});

  @override
  State<ViewJobOpportunitiesScreen> createState() => _ViewJobOpportunitiesScreenState();
}

class _ViewJobOpportunitiesScreenState extends State<ViewJobOpportunitiesScreen> {
  String? _selectedBranchFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<JobOpportunityCubit>().fetchJobOpportunities();
  }

  void _confirmDelete(String id) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      title: 'Confirm Delete',
      desc: 'Are you sure you want to delete this job opportunity?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await context.read<JobOpportunityCubit>().deleteJobOpportunity(id);
          context.read<JobOpportunityCubit>().fetchJobOpportunities();
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = !currentUser.isManagement;
    final canDelete = currentUser.isManagement;

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
              'Job Opportunities',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.80),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () async {
                navigateTo(context, BlocProvider.value(
                  value: context.read<JobOpportunityCubit>(),
                  child: const AddJobOpportunityScreen(),
                ));
                // Refresh list after adding
                if (context.mounted) {
                  context.read<JobOpportunityCubit>().fetchJobOpportunities();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w900)),
              backgroundColor: ColorsManger.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Stack(
        children: [
          const _JobOpportunitiesBackground(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + kToolbarHeight + 12,
              16,
              0,
            ),
            child: Column(
              children: [
                _PanelCard(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: ColorsManger.primary, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),

                BlocBuilder<JobOpportunityCubit, JobOpportunityState>(
                  buildWhen: (_, current) {
                    return current is JobOpportunityLoading ||
                        current is JobOpportunityLoaded ||
                        current is JobOpportunityError;
                  },
                  builder: (context, state) {
                    if (state is JobOpportunityLoading) {
                      return const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(color: ColorsManger.primary),
                        ),
                      );
                    }

                    if (state is JobOpportunityError) {
                      return Expanded(
                        child: Center(
                          child: _PanelCard(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error, size: 56, color: Colors.red),
                                const SizedBox(height: 12),
                                Text(
                                  state.error,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<JobOpportunityCubit>().fetchJobOpportunities();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text(
                                    'Retry',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorsManger.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    if (state is JobOpportunityLoaded) {
                      var opportunities = state.opportunities;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  opportunities = opportunities
                      .where((opp) => opp.fullName.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                // Apply branch filter
                if (_selectedBranchFilter != null && _selectedBranchFilter!.isNotEmpty) {
                  opportunities = opportunities
                      .where((opp) => opp.branchId == _selectedBranchFilter)
                      .toList();
                }

                if (opportunities.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: _PanelCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.work_off, size: 56, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'No job opportunities found',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.black.withValues(alpha: 0.60),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: Column(
                    children: [
                      ///Branch Filter Dropdown
                      /*if (canDelete && branches.length > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Filter by Branch',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBranchFilter,
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Branches'),
                                  ),
                                  ...branches.map((branch) {
                                    return DropdownMenuItem(
                                      value: branch['id'] as String,
                                      child: Text(branch['name'] as String),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBranchFilter = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),*/
                      const SizedBox(height: 8),

                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await context.read<JobOpportunityCubit>().fetchJobOpportunities();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                            itemCount: opportunities.length,
                            itemBuilder: (context, index) {
                              final opportunity = opportunities[index];
                              return JobOpportunityCard(
                                opportunity: opportunity,
                                canDelete: canDelete,
                                onDelete: () => _confirmDelete(opportunity.id),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobOpportunitiesBackground extends StatelessWidget {
  const _JobOpportunitiesBackground();

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




