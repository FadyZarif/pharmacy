import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/app_regex.dart';
import 'package:pharmacy/core/helpers/extensions.dart';
import 'package:pharmacy/core/helpers/file_helper.dart' as file_helper;
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
  final _vocationBalanceMinutesController = TextEditingController();

  Role _selectedRole = Role.staff;
  bool _isActive = true;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _shiftHoursController.text = '8';
    _vocationBalanceMinutesController.text = '${8*21*60}'; // Default 21 days in minutes
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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
        final topPad = MediaQuery.of(context).padding.top;
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
                  'Add User',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.80),
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              const _AddUserBackground(),
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    topPad + kToolbarHeight + 12,
                    16,
                    22,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PanelCard(
                          child: Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 56,
                                    backgroundColor:
                                        ColorsManger.primary.withValues(alpha: 0.12),
                                    backgroundImage: _selectedImageBytes != null
                                        ? MemoryImage(_selectedImageBytes!)
                                        : null,
                                    child: _selectedImageBytes == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 56,
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
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _PanelCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle('Personal Information'),
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
                              const SizedBox(height: 14),
                              AppTextFormField(
                                controller: _emailController,
                                labelText: 'Email',
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.email),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter email';
                                  }
                                  if (!AppRegex.isEmailValid(value)) {
                                    return 'Please enter valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              AppTextFormField(
                                controller: _phoneController,
                                labelText: 'Phone',
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.phone),
                                keyboardType: TextInputType.phone,
                                maxLength: 11,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                              const SizedBox(height: 14),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        _PanelCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle('Work Information'),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<Role>(
                                initialValue: _selectedRole,
                                decoration: InputDecoration(
                                  labelText: 'Role',
                                  prefixIcon: const Icon(Icons.work),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
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
                                    .map(
                                      (role) => DropdownMenuItem(
                                        value: role,
                                        child: Text(role.name.toUpperCase()),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 14),
                              AppTextFormField(
                                controller: _printCodeController,
                                labelText: 'Print Code (Optional)',
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.qr_code),
                              ),
                              const SizedBox(height: 14),
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
                              const SizedBox(height: 14),
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
                                    final totalMinutes = int.tryParse(
                                          _vocationBalanceMinutesController.text,
                                        ) ??
                                        0;
                                    final shiftHours =
                                        int.tryParse(_shiftHoursController.text) ?? 1;
                                    final shiftMinutes = shiftHours * 60;
                                    final days = totalMinutes ~/ shiftMinutes;
                                    final remainingMinutes = totalMinutes % shiftMinutes;
                                    final hours = remainingMinutes ~/ 60;
                                    final minutes = remainingMinutes % 60;
                                    return 'Vacation balance is $days days, $hours hours and $minutes minutes';
                                  }(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withValues(alpha: 0.60),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
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
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Active Status',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorsManger.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.person_add),
                            label: const Text(
                              'Add User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
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
            ],
          ),
        );
      },
    ),
);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = getIt<UsersCubit>();

    // Get vacation balance in minutes
    final shiftHours = int.parse(_shiftHoursController.text);
    final vocationBalanceMinutes = int.parse(_vocationBalanceMinutesController.text);

    await cubit.addUser(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      printCode: _printCodeController.text.isEmpty
          ? null
          : _printCodeController.text,
      shiftHours: shiftHours,
      vocationBalanceMinutes: vocationBalanceMinutes,
      role: _selectedRole,
      isActive: _isActive,
      imageBytes: _selectedImageBytes,
      imageName: _selectedImageName,
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: true, // Important for web
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      Uint8List? bytes;

      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null && !kIsWeb) {
        bytes = await file_helper.readFileBytes(file.path!);
      }

      if (bytes != null) {
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = file.name;
        });
      }
    }
  }
}

class _AddUserBackground extends StatelessWidget {
  const _AddUserBackground();

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

  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
  const _SectionTitle(this.title);

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

