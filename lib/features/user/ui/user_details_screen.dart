import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/core/widgets/profile_circle.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import 'package:pharmacy/features/user/ui/add_user_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:pharmacy/core/helpers/constants.dart';

class UserDetailsScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: const Text('User Details'),
        centerTitle: true,
        backgroundColor: ColorsManger.primary,
        foregroundColor: Colors.white,
        actions: [
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddUserScreen(),
                ),
              );
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
                    ProfileCircle(photoUrl: user.photoUrl, size: 100),
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
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Delete User',
      desc: 'Are you sure you want to delete ${user.name}? This action cannot be undone.',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          // Delete user
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();

          // Close loading
          if (!context.mounted) return;
          Navigator.pop(context);

          // Show success
          await defToast2(
            context: context,
            msg: 'User deleted successfully',
            dialogType: DialogType.success,
          );

          // Go back
          if (!context.mounted) return;
          Navigator.pop(context);
        } catch (e) {
          // Close loading
          if (!context.mounted) return;
          Navigator.pop(context);

          // Show error
          await defToast2(
            context: context,
            msg: 'Error deleting user: $e',
            dialogType: DialogType.error,
          );
        }
      },
      btnOkColor: Colors.red,
    ).show();
  }
}

