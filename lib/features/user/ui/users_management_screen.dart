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
import 'package:pharmacy/features/branch/ui/branch_monthly_target_screen.dart';
import 'package:pharmacy/features/branch/logic/branch_target_cubit.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  String _searchQuery = '';
  Role? _selectedRoleFilter;
  bool? _selectedActiveFilter; // null = all, true = active only, false = inactive only
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<UsersCubit>(),
      child: Scaffold(
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
                'Users · ${currentUser.currentBranch.name}',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              actions: [
                // Monthly Target button - Admin only
                if (currentUser.role == Role.admin)
                  IconButton(
                    icon: Icon(Icons.bar_chart, color: ColorsManger.primary.withValues(alpha: 0.95)),
                    tooltip: 'Monthly Target',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => getIt<BranchTargetCubit>(),
                            child: const BranchMonthlyTargetScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.work, color: ColorsManger.primary.withValues(alpha: 0.95)),
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
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            const _UsersBackground(),
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by name or phone...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.16)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.16)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: ColorsManger.primary.withValues(alpha: 0.65), width: 1.5),
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
                        const SizedBox(height: 10),

                        // Active/Inactive Filter
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildActiveFilterChip('All Status', null),
                              const SizedBox(width: 8),
                              _buildActiveFilterChip('Active Only', true),
                              const SizedBox(width: 8),
                              _buildActiveFilterChip('Inactive Only', false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Users List
                Expanded(
                  child: BlocBuilder<UsersCubit, UsersState>(
                    buildWhen: (_, current) =>
                        current is FetchUsersLoading ||
                        current is FetchUsersError ||
                        current is FetchUsersSuccess,
                    builder: (context, state) {
                      if (state is FetchUsersLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: ColorsManger.primary),
                        );
                      }

                      if (state is FetchUsersError) {
                        return Center(
                          child: _PanelCard(
                            margin: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                                const SizedBox(height: 10),
                                Text(
                                  'Error: ${state.error}',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state is FetchUsersSuccess) {
                        if (state.users.isEmpty) {
                          return Center(
                            child: _PanelCard(
                              margin: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_outline, size: 72, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No users found in this branch',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Apply filters using cubit
                        final users = context.read<UsersCubit>().filterUsers(
                              searchQuery: _searchQuery,
                              selectedRole: _selectedRoleFilter,
                              isActive: _selectedActiveFilter,
                            );

                        if (users.isEmpty) {
                          return Center(
                            child: _PanelCard(
                              margin: const EdgeInsets.all(16),
                              child: Text(
                                'No users match your search',
                                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
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

  Widget _buildActiveFilterChip(String label, bool? isActive) {
    final isSelected = _selectedActiveFilter == isActive;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive != null)
            Icon(
              isActive ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: isSelected
                  ? (isActive ? Colors.green : Colors.red)
                  : Colors.grey[600],
            ),
          if (isActive != null) const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedActiveFilter = selected ? isActive : null;
        });
      },
      selectedColor: isActive == null
          ? ColorsManger.primary.withValues(alpha: 0.2)
          : (isActive
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2)),
      checkmarkColor: isActive == null
          ? ColorsManger.primary
          : (isActive ? Colors.green : Colors.red),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected
            ? (isActive == null
                ? ColorsManger.primary
                : (isActive ? Colors.green : Colors.red))
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    return Opacity(
      opacity: user.isActive ? 1.0 : 0.6, // Dim inactive users
      child: _PanelCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        borderSide: user.isActive
            ? BorderSide(color: Colors.grey.withValues(alpha: 0.16))
            : BorderSide(color: Colors.red.withValues(alpha: 0.30), width: 1.5),
        child: InkWell(
          onTap: () => navigateTo(context, ProfileScreen(user: user)),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              // Profile Picture
              Stack(
                children: [
                  ProfileCircle(photoUrl: user.photoUrl, size: 26),
                  if (!user.isActive)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.block,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              decoration: user.isActive ? null : TextDecoration.lineThrough,
                              color: user.isActive ? Colors.black87 : Colors.grey[700],
                            ),
                          ),
                        ),
                        if (!user.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.22)),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.black.withValues(alpha: 0.45)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            user.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getRoleColor(user.role).withValues(alpha: 0.18)),
                          ),
                          child: Text(
                            user.role.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _getRoleColor(user.role),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: user.isActive
                                ? Colors.green.withValues(alpha: 0.10)
                                : Colors.red.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            user.isActive ? Icons.check_circle : Icons.cancel,
                            color: user.isActive ? Colors.green : Colors.red,
                            size: 18,
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

class _UsersBackground extends StatelessWidget {
  const _UsersBackground();

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
  final BorderSide? borderSide;

  const _PanelCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 0),
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (borderSide?.color ?? Colors.grey.withValues(alpha: 0.16)),
          width: borderSide?.width ?? 1,
        ),
        boxShadow: _panelShadow(),
      ),
      child: child,
    );
  }
}

