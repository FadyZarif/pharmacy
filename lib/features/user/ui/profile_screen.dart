import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/helpers/extensions.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/user/logic/users_cubit.dart';
import 'package:pharmacy/features/user/logic/users_state.dart';
import 'package:pharmacy/features/user/ui/edit_user_screen.dart';
import 'package:pharmacy/features/user/ui/edit_profile_screen.dart';

import '../../../core/widgets/profile_circle.dart';
import '../data/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel userModel;

  @override
  void initState() {
    userModel = currentUser.uid == widget.user.uid ? currentUser : widget.user;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<UsersCubit>(),
      child: BlocConsumer<UsersCubit, UsersState>(
        listenWhen: (context, state) =>
            state is DeleteUserLoading ||
            state is DeleteUserSuccess ||
            state is DeleteUserError,
        listener: (context, state) async {
          if (state is DeleteUserLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(
                  color: ColorsManger.primary,
                ),
              ),
            );
          } else if (state is DeleteUserSuccess) {
            context.pop();
            await defToast2(
              context: context,
              msg: 'User deleted successfully',
              dialogType: DialogType.success,
            );
            if (context.mounted) {
              Navigator.pop(context);
            }
          } else if (state is DeleteUserError) {
            context.pop();
            await defToast2(
              context: context,
              msg: state.error,
              dialogType: DialogType.error,
            );
          }
        },
        builder: (context, state) {
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
                    'Profile',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.80),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  actions: [
                    // Edit Profile Button (for the current user viewing their own profile)
                    if (currentUser.uid == widget.user.uid)
                      IconButton(
                        icon: Icon(Icons.edit, color: ColorsManger.primary.withValues(alpha: 0.95)),
                        tooltip: 'Edit Profile',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(user: userModel),
                            ),
                          );

                          // Refresh if profile was updated
                          if (result == true) {
                            setState(() {
                              userModel = currentUser;
                            });
                            if (context.mounted && Navigator.canPop(context)) {
                              Navigator.pop(context, true);
                            }
                          }
                        },
                      ),
                    // Edit User Button (for management viewing other users)
                    if (currentUser.uid != widget.user.uid &&
                        currentUser.isManagement &&
                        (currentUser.role.index < widget.user.role.index))
                      IconButton(
                        icon: Icon(Icons.edit, color: ColorsManger.primary.withValues(alpha: 0.95)),
                        tooltip: 'Edit User',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditUserScreen(user: userModel),
                            ),
                          );

                          // If user was updated or deleted, go back to previous screen
                          if (result == true && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    // Delete Button (Admin only, not for own profile)
                    if (currentUser.role == Role.admin && currentUser.uid != widget.user.uid)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete User',
                        onPressed: () => _showDeleteConfirmation(context),
                      ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
            body: Stack(
              children: [
                const _ProfileBackground(),
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                      16,
                      22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PanelCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              ProfileCircle(photoUrl: userModel.photoUrl, size: 30),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userModel.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userModel.branches.isEmpty
                                          ? 'No branch'
                                          : userModel.branches.map((e) => e.name).join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _RolePill(role: userModel.role, color: _getRoleColor(userModel.role)),
                                  const SizedBox(height: 8),
                                  _StatusPill(isActive: userModel.isActive),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        _PanelCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(title: 'Contact'),
                              const SizedBox(height: 12),
                              _InfoRow(label: 'Email', value: userModel.email, icon: Icons.email),
                              const SizedBox(height: 10),
                              _InfoRow(label: 'Phone', value: userModel.phone, icon: Icons.phone),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        _PanelCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(title: 'Work'),
                              const SizedBox(height: 12),
                              _InfoRow(
                                label: 'Print Code',
                                value: userModel.printCode?.isNotEmpty == true ? userModel.printCode! : 'N/A',
                                icon: Icons.fingerprint,
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                label: 'Shift Hours',
                                value: '${userModel.shiftHours} hours',
                                icon: Icons.access_time,
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                label: 'Overtime Hours',
                                value: '${userModel.overTimeHours} hours',
                                icon: Icons.add_alarm,
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                label: 'Vacation Balance',
                                value: userModel.vocationBalance,
                                icon: Icons.beach_access,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${userModel.name}?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              getIt<UsersCubit>().deleteUser(userModel.uid);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ColorsManger.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: ColorsManger.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  final Role role;
  final Color color;
  const _RolePill({required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? Icons.check_circle : Icons.cancel, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
