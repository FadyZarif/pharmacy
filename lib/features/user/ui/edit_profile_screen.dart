import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/helpers/extensions.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:pharmacy/features/user/logic/users_cubit.dart';
import 'package:pharmacy/features/user/logic/users_state.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;

  File? _selectedImage;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.user.phone);
    _currentPhotoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
            state is UpdateUserError,
        listener: (context, state) async {
          if (state is UpdateUserLoading) {
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
            bool userUpdated = await checkIsLogged();
            if(userUpdated && context.mounted){
              context.pop();
              await defToast2(
                context: context,
                msg: 'Profile updated successfully',
                dialogType: DialogType.success,
              );
            }

            if (context.mounted) {
              Navigator.pop(context, true);
            }
          } else if (state is UpdateUserError) {
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
              title: const Text(
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

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

                      const SizedBox(height: 12),
                      Text(
                        'Tap to change photo',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Phone Number Field
                      AppTextFormField(
                        controller: _phoneController,
                        labelText: 'Phone Number',
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

                      const SizedBox(height: 40),

                      // Save Button
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
                            'Save Changes',
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

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = getIt<UsersCubit>();

    // Keep all other data the same, only update phone and image
    await cubit.updateUser(
      uid: widget.user.uid,
      name: widget.user.name, // Keep same
      phone: _phoneController.text,
      printCode: widget.user.printCode, // Keep same
      shiftHours: widget.user.shiftHours, // Keep same
      role: widget.user.role, // Keep same
      isActive: widget.user.isActive, // Keep same
      hasRequestsPermission: widget.user.hasRequestsPermission, // Keep same
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

