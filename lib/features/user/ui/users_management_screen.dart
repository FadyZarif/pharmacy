import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/profile_circle.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import 'package:pharmacy/features/user/logic/users_cubit.dart';
import 'package:pharmacy/features/user/logic/users_state.dart';
import 'package:pharmacy/features/user/ui/profile_screen.dart';
import 'package:pharmacy/features/user/ui/add_user_screen.dart';
import 'package:pharmacy/features/job_opportunity/ui/view_job_opportunities_screen.dart';
import 'package:pharmacy/features/job_opportunity/logic/job_opportunity_cubit.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  String _searchQuery = '';
  Role? _selectedRoleFilter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<UsersCubit>(),
      child: Scaffold(
        backgroundColor: ColorsManger.primaryBackground,
        appBar: AppBar(
          title: Text('Users [${currentUser.currentBranch.name}]', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: ColorsManger.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.work),
              tooltip: 'Job Opportunities',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: getIt<JobOpportunityCubit>(),
                      child: const ViewJobOpportunitiesScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search & Filter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(

                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    controller: TextEditingController(text: _searchQuery),
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,color: Colors.red,),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Role Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', null),
                        const SizedBox(width: 8),
                        _buildFilterChip('Staff', Role.staff),
                        const SizedBox(width: 8),
                        _buildFilterChip('Sub Manager', Role.subManager),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Users List
            Expanded(
              child: BlocBuilder<UsersCubit, UsersState>(
                buildWhen: (_, current) => current is FetchUsersLoading || current is FetchUsersError || current is FetchUsersSuccess,
                builder: (context, state) {
                  if (state is FetchUsersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is FetchUsersError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is FetchUsersSuccess) {
                    if (state.users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No users found in this branch',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    // Apply filters using cubit
                    var users = context.read<UsersCubit>().filterUsers(
                      searchQuery: _searchQuery,
                      selectedRole: _selectedRoleFilter,
                    );

                    if (users.isEmpty) {
                      return Center(
                        child: Text(
                          'No users match your search',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserCard(user);
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            navigateTo(context, const AddUserScreen());
          },
          backgroundColor: ColorsManger.primary,
          child: const Icon(Icons.person_add, color: Colors.white),
          // icon: const Icon(Icons.person_add, color: Colors.white),
          // label: const Text('Add User', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, Role? role) {
    final isSelected = _selectedRoleFilter == role;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRoleFilter = selected ? role : null;
        });
      },
      selectedColor: ColorsManger.primary.withValues(alpha: 0.2),
      checkmarkColor: ColorsManger.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? ColorsManger.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          navigateTo(context, ProfileScreen(user: user));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              ProfileCircle(photoUrl: user.photoUrl, size: 40),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.role.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getRoleColor(user.role),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Indicator
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  user.isActive ? Icons.check_circle : Icons.cancel,
                  color: user.isActive ? Colors.green : Colors.red,
                  size: 24,
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.admin:
        return Colors.purple;
      case Role.manager:
        return Colors.blue;
      case Role.subManager:
        return Colors.orange;
      case Role.staff:
        return Colors.green;
    }
  }
}

