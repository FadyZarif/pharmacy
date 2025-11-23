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
      appBar: AppBar(
        title: const Text('Job Opportunities',style: TextStyle(fontWeight: FontWeight.bold),),
        foregroundColor: Colors.white,
        centerTitle: true,
        backgroundColor: ColorsManger.primary,
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
              label: const Text('Add'),
              backgroundColor: ColorsManger.primary,
        foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          BlocBuilder<JobOpportunityCubit, JobOpportunityState>(
            buildWhen: (_, current) {
              return current is JobOpportunityLoading ||
                  current is JobOpportunityLoaded ||
                  current is JobOpportunityError;
            },
            builder: (context, state) {
              if (state is JobOpportunityLoading) {
                return const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state is JobOpportunityError) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(state.error),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<JobOpportunityCubit>().fetchJobOpportunities();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
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
                  return const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No job opportunities found'),
                        ],
                      ),
                    ),
                  );
                }

                // Get unique branches for filter (for admin/manager)
                final branches = opportunities
                    .map((opp) => {'id': opp.branchId, 'name': opp.branchName})
                    .toSet()
                    .toList();

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
    );
  }
}




