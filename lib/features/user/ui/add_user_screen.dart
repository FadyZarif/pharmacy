import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/app_regex.dart';
import 'package:pharmacy/core/helpers/extensions.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:pharmacy/features/user/logic/users_cubit.dart';
import 'package:pharmacy/features/user/logic/users_state.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _printCodeController = TextEditingController();
  final _shiftHoursController = TextEditingController();
  final _vocationBalanceHoursController = TextEditingController();

  Role _selectedRole = Role.staff;
  bool _isActive = true;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _shiftHoursController.text = '8';
    _vocationBalanceHoursController.text = '${8*21}'; // Default 21 days
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _printCodeController.dispose();
    _shiftHoursController.dispose();
    _vocationBalanceHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
  value: getIt<UsersCubit>(),
  child: BlocConsumer<UsersCubit, UsersState>(
    listenWhen: (context, state) =>
        state is AddUserLoading ||
        state is AddUserSuccess ||
        state is AddUserError,
      listener: (context, state) async {
        if( state is AddUserLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const Center(
              child: CircularProgressIndicator(
                color: ColorsManger.primary,
              ),
            ),
          );

        }
        else if (state is AddUserSuccess) {
          context.pop();
          await defToast2(
            context: context,
            msg: 'User created successfully',
            dialogType: DialogType.success,
          );
          if (context.mounted) {
            Navigator.pop(context);
          }
        } else if (state is AddUserError) {
          context.pop();
          await defToast2(
            context: context,
            msg: state.error,
            dialogType: DialogType.error,
          );
          print(state.error);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: ColorsManger.primaryBackground,
          appBar: AppBar(
            title: const Text('Add User', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: ColorsManger.primary,
            foregroundColor: Colors.white,
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
                        child:  GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: ColorsManger.primary.withValues(alpha: 0.2),
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : null,
                                child: _selectedImage == null
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

                AppTextFormField(
                  controller: _emailController,
                  labelText: 'Email',
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty ) {
                      return 'Please enter email';
                    }
                    if (!AppRegex.isEmailValid(value)) {
                      return 'Please enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                    if (!AppRegex.isPhoneNumberValid(value)) {
                      return 'Please enter valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextFormField(
                  controller: _passwordController,
                  labelText: 'Password',
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
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
                    });
                  },
                ),
                const SizedBox(height: 16),

                AppTextFormField(
                  controller: _printCodeController,
                  labelText: 'Print Code (Optional)',
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.qr_code),
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
                  onChanged: (_) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 16),

                AppTextFormField(
                  controller: _vocationBalanceHoursController,
                  labelText: 'Vacation Hours Balance',
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.beach_access),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vacation hours balance';
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
                    'Vacation balance is ${((int.tryParse(_vocationBalanceHoursController.text) ?? 0) ~/ (int.tryParse(_shiftHoursController.text) ?? 1))} days and ${((int.tryParse(_vocationBalanceHoursController.text) ?? 0) % (int.tryParse(_shiftHoursController.text) ?? 1))} hours',
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
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManger.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                            'Add User',
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = getIt<UsersCubit>();

    // Calculate vacation balance hours from days
    final shiftHours = int.parse(_shiftHoursController.text);
    final vocationBalanceHours = int.parse(_vocationBalanceHoursController.text);

    await cubit.addUser(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      printCode: _printCodeController.text.isEmpty
          ? null
          : _printCodeController.text,
      shiftHours: shiftHours,
      vocationBalanceHours: vocationBalanceHours,
      role: _selectedRole,
      isActive: _isActive,
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
}

