import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/extensions.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:pharmacy/features/user/logic/users_cubit.dart';
import 'package:pharmacy/features/user/logic/users_state.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _printCodeController;
  late final TextEditingController _shiftHoursController;
  late final TextEditingController _vocationBalanceMinutesController;

  late Role _selectedRole;
  late bool _isActive;
  late bool _hasRequestsPermission;
  File? _selectedImage;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    // Initialize with current user data
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _printCodeController = TextEditingController(text: widget.user.printCode ?? '');
    _shiftHoursController = TextEditingController(text: widget.user.shiftHours.toString());
    _vocationBalanceMinutesController = TextEditingController(text: widget.user.vocationBalanceMinutes.toString());


    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
    _hasRequestsPermission = widget.user.hasRequestsPermission;
    _currentPhotoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _printCodeController.dispose();
    _shiftHoursController.dispose();
    _vocationBalanceMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<UsersCubit>(),
      child: BlocConsumer<UsersCubit, UsersState>(
        listenWhen: (context, state) =>
            state is UpdateUserLoading ||
            state is UpdateUserSuccess ||
            state is UpdateUserError ||
            state is DeleteUserLoading ||
            state is DeleteUserSuccess ||
            state is DeleteUserError,
        listener: (context, state) async {
          if (state is UpdateUserLoading || state is DeleteUserLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(
                  color: ColorsManger.primary,
                ),
              ),
            );
          } else if (state is UpdateUserSuccess) {
            context.pop();
            await defToast2(
              context: context,
              msg: 'User updated successfully',
              dialogType: DialogType.success,
            );
            if (context.mounted) {
              // Return true to indicate successful update
              Navigator.pop(context, true);
            }
          } else if (state is UpdateUserError) {
            context.pop();
            await defToast2(
              context: context,
              msg: state.error,
              dialogType: DialogType.error,
            );
          } else if (state is DeleteUserSuccess) {
            context.pop();
            await defToast2(
              context: context,
              msg: 'User deleted successfully',
              dialogType: DialogType.success,
            );
            if (context.mounted) {
              // Return true to indicate successful deletion
              Navigator.pop(context, true);
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
              title: const Text('Edit User', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              backgroundColor: ColorsManger.primary,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _showDeleteConfirmation,
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image Section
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: ColorsManger.primary.withValues(alpha: 0.2),
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                                        ? NetworkImage(_currentPhotoUrl!)
                                        : null) as ImageProvider?,
                                child: (_selectedImage == null &&
                                       (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty))
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: ColorsManger.primary,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ColorsManger.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Personal Information Section
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 12),

                      AppTextFormField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email (Read-only)
                      /*AppTextFormField(
                        controller: TextEditingController(text: widget.user.email),
                        labelText: 'Email',
                        fillColor: Colors.grey.shade200,
                        prefixIcon: const Icon(Icons.email),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),*/

                      AppTextFormField(
                        controller: _phoneController,
                        labelText: 'Phone',
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.phone),
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (value.length != 11) {
                            return 'Phone number must be 11 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Work Information Section
                      _buildSectionTitle('Work Information'),
                      const SizedBox(height: 12),

                      // Role Dropdown
                      DropdownButtonFormField<Role>(
                        initialValue: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: const Icon(Icons.work),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: Role.values
                            .where((role) {
                              // Admin can assign any role, Manager can only assign staff/subManager
                              if (currentUser.role == Role.admin) return true;
                              return role == Role.staff || role == Role.subManager;
                            })
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role.name.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                            // Reset permission if role is not subManager
                            if (_selectedRole != Role.subManager) {
                              _hasRequestsPermission = false;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      AppTextFormField(
                        controller: _printCodeController,
                        labelText: 'Print Code (Optional)',
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.fingerprint),
                      ),
                      const SizedBox(height: 16),

                      AppTextFormField(
                        controller: _shiftHoursController,
                        labelText: 'Shift Hours',
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.access_time),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter shift hours';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      AppTextFormField(
                        controller: _vocationBalanceMinutesController,
                        labelText: 'Vacation Balance (Minutes)',
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.beach_access),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter vacation balance in minutes';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter valid number';
                          }
                          return null;
                        },
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          () {
                            final totalMinutes = int.tryParse(_vocationBalanceMinutesController.text) ?? 0;
                            final shiftHours = int.tryParse(_shiftHoursController.text) ?? 1;
                            final shiftMinutes = shiftHours * 60;
                            final days = totalMinutes ~/ shiftMinutes;
                            final remainingMinutes = totalMinutes % shiftMinutes;
                            final hours = remainingMinutes ~/ 60;
                            final minutes = remainingMinutes % 60;
                            return 'Vacation balance is $days days, $hours hours and $minutes minutes';
                          }(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Active Status Switch
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isActive ? Icons.check_circle : Icons.cancel,
                                  color: _isActive ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Active Status',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                              activeTrackColor: ColorsManger.primary,
                            ),
                          ],
                        ),
                      ),

                      // Requests Permission Switch (Only for SubManagers)
                      if (_selectedRole == Role.subManager && currentUser.isManagement) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      _hasRequestsPermission ? Icons.admin_panel_settings : Icons.block,
                                      color: _hasRequestsPermission ? Colors.blue : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Requests Management Permission',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _hasRequestsPermission,
                                onChanged: (value) {
                                  setState(() {
                                    _hasRequestsPermission = value;
                                  });
                                },
                                activeTrackColor: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsManger.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Update User',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = getIt<UsersCubit>();

    await cubit.updateUser(
      uid: widget.user.uid,
      name: _nameController.text,
      phone: _phoneController.text,
      printCode: _printCodeController.text.isEmpty ? null : _printCodeController.text,
      shiftHours: int.parse(_shiftHoursController.text),
      vocationBalanceMinutes: int.parse(_vocationBalanceMinutesController.text),
      role: _selectedRole,
      isActive: _isActive,
      hasRequestsPermission: _selectedRole == Role.subManager ? _hasRequestsPermission : null,
      imageFile: _selectedImage,
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    }
  }

  void _showDeleteConfirmation() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      headerAnimationLoop: false,
      title: 'Delete User',
      desc: 'Are you sure you want to delete this user? This action cannot be undone.',
      btnCancelOnPress: () {},
      btnOkOnPress: _handleDelete,
      btnOkText: 'Delete',
    ).show();

  }

  Future<void> _handleDelete() async {
    final cubit = getIt<UsersCubit>();
    await cubit.deleteUser(widget.user.uid);
  }
}

