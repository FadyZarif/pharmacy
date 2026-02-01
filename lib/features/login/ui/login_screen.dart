import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/branch/ui/branch_selection_screen.dart';
import 'package:pharmacy/features/employee/ui/employee_layout.dart';
import 'package:pharmacy/features/login/logic/login_cubit.dart';
import 'package:pharmacy/features/login/logic/login_states.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/app_regex.dart';
import '../../../core/helpers/constants.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/loading_button.dart';
import '../../user/data/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey();

  static const _maxContentWidth = 520.0;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<LoginCubit>(),
      child: Builder(
        builder: (context) {
          LoginCubit cubit = context.read<LoginCubit>();
          return BlocConsumer<LoginCubit, LoginStates>(
            listener: (context, state) {
              if (state is LoginSuccessState) {
                defToast2(
                  msg: 'Successfully SignIn',
                  context: context,
                  dialogType: DialogType.success,
                ).then((value) {
                  if (!context.mounted) return;
                  // navigateToReplacement(context,currentUser.role == Role.superVisor?SupervisorLayout(): AdminLayout());
                  switch (currentUser.role) {
                    case Role.admin:
                    case Role.manager:
                      navigateToReplacement(context, BranchSelectionScreen());
                      break;
                    case Role.subManager:
                    case Role.staff:
                      navigateToReplacement(context, EmployeeLayout());
                      break;
                  }
                });
              }
              if(state is LoginErrorState){
                defToast2(
                  msg: state.error,
                  context: context,
                  dialogType: DialogType.error,
                );
              }
            },
            builder: (context, state) {
              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: Scaffold(
                  backgroundColor: ColorsManger.secondaryBackground,
                  body: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF6F8FF),
                          Color(0xFFEAFBFF),
                          Color(0xFFF2ECFF),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Soft glow blobs (background decoration)
                                Positioned(
                                  left: -90,
                                  top: -80,
                                  child: _GlowBlob(
                                    size: 220,
                                    color: const Color(0xFF17D5E6).withValues(alpha: 0.18),
                                  ),
                                ),
                                Positioned(
                                  right: -90,
                                  top: 120,
                                  child: _GlowBlob(
                                    size: 240,
                                    color: ColorsManger.primary.withValues(alpha: 0.14),
                                  ),
                                ),
                                Positioned(
                                  left: -110,
                                  bottom: -90,
                                  child: _GlowBlob(
                                    size: 260,
                                    color: const Color(0xFFFF5BC5).withValues(alpha: 0.10),
                                  ),
                                ),
                                Form(
                                  key: formKey,
                                  child: AutofillGroup(
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 8),
                                        // Logo
                                        Container(
                                          width: 124,
                                          height: 124,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.86),
                                            borderRadius: BorderRadius.circular(34),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.7),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.06),
                                                blurRadius: 22,
                                                offset: const Offset(0, 14),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(26),
                                            child: Image.asset(
                                              'assets/images/app_launcher_icon.png',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Emad Fawzy Pharmacy',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black.withValues(alpha: 0.88),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Sign in to continue',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: ColorsManger.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Card
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: ColorsManger.secondaryBackground.withValues(alpha: 0.92),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.6),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 26,
                                                offset: const Offset(0, 16),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                'Welcome back',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black.withValues(alpha: 0.86),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Use your work email and password',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: ColorsManger.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              AppTextFormField(
                                                controller: emailController,
                                                autofillHints: const [AutofillHints.email],
                                                labelText: 'Email',
                                                fillColor: ColorsManger.primaryBackground,
                                                prefixIcon: const Icon(Icons.email_outlined),
                                                keyboardType: TextInputType.emailAddress,
                                                textInputAction: TextInputAction.next,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty ||
                                                      !AppRegex.isEmailValid(value)) {
                                                    return 'Please enter valid email';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 14),
                                              AppTextFormField(
                                                controller: passwordController,
                                                autofillHints: const [AutofillHints.password],
                                                labelText: 'Password',
                                                fillColor: ColorsManger.primaryBackground,
                                                prefixIcon: const Icon(Icons.lock_outline),
                                                obscureText: cubit.isPassword,
                                                textInputAction: TextInputAction.done,
                                                suffixIcon: IconButton(
                                                  onPressed: () {
                                                    cubit.changePasswordVisibility();
                                                  },
                                                  icon: Icon(cubit.suffixIcon),
                                                ),
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return 'please enter password';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 18),
                                              LoadingButton(
                                                text: 'Sign In',
                                                controller: cubit.btnController,
                                                onPressed: () {
                                                  FocusScope.of(context).requestFocus(FocusNode());
                                                  if (formKey.currentState!.validate()) {
                                                    cubit.login(
                                                      email: emailController.text,
                                                      password: passwordController.text,
                                                    );
                                                  } else {
                                                    cubit.btnController.error();
                                                    Future.delayed(const Duration(seconds: 3), () {
                                                      cubit.btnController.reset();
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'Powered by Double Click',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black.withValues(alpha: 0.55),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16.0),
                                          child: Image.asset(
                                            'assets/images/3bb522e6-c73d-42ea-b903-8205085c8fbb.png',
                                            width: 120.0,
                                            height: 120.0,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
