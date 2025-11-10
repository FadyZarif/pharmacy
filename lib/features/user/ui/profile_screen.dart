import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/helpers/extensions.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/features/user/logic/users_cubit.dart';
import 'package:pharmacy/features/user/logic/users_state.dart';
import 'package:pharmacy/features/user/ui/edit_user_screen.dart';

import '../../../core/widgets/profile_circle.dart';
import '../data/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

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
            appBar: AppBar(
              title: const Text('User Details'),
              centerTitle: true,
              backgroundColor: ColorsManger.primary,
              foregroundColor: Colors.white,
              actions: [
                // Edit Button
                if (currentUser.isManagement)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditUserScreen(user: user),
                        ),
                      );

                      // If user was updated or deleted, go back to previous screen
                      if (result == true && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                // Delete Button
                if (currentUser.role == Role.admin)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmation(context),
                  ),
              ],
            ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5)
                  ],
                ),
                child: Column(
                  children: [
                    // Profile Photo
                    ProfileCircle(photoUrl: user.photoUrl, size: 65),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Role
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.role.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Branches
                    Text(
                      '[${user.branches.map((e) => e.name).join(', ')}]',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Active Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: user.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: user.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user.isActive ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: user.isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: user.isActive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contact Information
              _buildInfoSection(
                title: 'Contact Information',
                children: [
                  _buildInfoField('Email', user.email, Icons.email),
                  _buildInfoField('Phone', user.phone, Icons.phone),
                ],
              ),
              const SizedBox(height: 20),

              // Work Information
              _buildInfoSection(
                title: 'Work Information',
                children: [
                  _buildInfoField(
                      'Print Code', user.printCode ?? 'N/A', Icons.qr_code),
                  _buildInfoField('Shift Hours', '${user.shiftHours} hours',
                      Icons.access_time),
                  _buildInfoField('Overtime Hours', '${user.overTimeHours} hours',
                      Icons.add_alarm),
                  _buildInfoField('Vacation Balance', user.vocationBalance,
                      Icons.beach_access),
                ],
              ),
            ],
          ),
        ),
      ),
    );
        },
      ),
    );
  }

  Widget _buildInfoSection(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppTextFormField(
        controller: TextEditingController(text: value),
        labelText: label,
        prefixIcon: Icon(icon),
        readOnly: true,
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
          'Are you sure you want to delete ${user.name}?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              getIt<UsersCubit>().deleteUser(user.uid);
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
