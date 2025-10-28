import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/employee/ui/employee_layout.dart';
import 'package:pharmacy/features/login/logic/login_cubit.dart';
import 'package:pharmacy/features/login/logic/login_states.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/app_regex.dart';
import '../../../core/helpers/constants.dart';
import '../../../core/widgets/loading_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey();

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
                  navigateToReplacement(context, EmployeeLayout());
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorsManger.primaryBackground,
                          Color(0x5FA1E6ED),
                        ],
                        stops: [0.0, 1.0],
                        begin: AlignmentDirectional(0.87, -1.0),
                        end: AlignmentDirectional(-0.87, 1.0),
                      ),
                    ),
                    alignment: AlignmentDirectional(0.0, -1.0),
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional(0.0, -1.0),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0,
                                      100.0,
                                      0.0,
                                      0.0,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.asset(
                                        'assets/images/0cf33877-26ff-4719-a156-8274f6498bb8.png',
                                        width: 200.0,
                                        height: 200.0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Container(
                                      width: double.infinity,
                                      constraints: BoxConstraints(
                                        maxWidth: 570.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ColorsManger.secondaryBackground,
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 4.0,
                                            color: Color(0x33000000),
                                            offset: Offset(0.0, 2.0),
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                      ),
                                      child: Align(
                                        alignment: AlignmentDirectional(
                                          0.0,
                                          0.0,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(32.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Welcome',
                                                textAlign: TextAlign.center,
                                                style:
                                                    GoogleFonts.shadowsIntoLight(
                                                      fontSize: 36,
                                                      letterSpacing: 0.0,
                                                    ),
                                              ),
                                              Padding(
                                                padding:
                                                    EdgeInsetsDirectional.fromSTEB(
                                                      0.0,
                                                      0.0,
                                                      0.0,
                                                      16.0,
                                                    ),
                                                child: Container(
                                                  width: double.infinity,
                                                  child: TextFormField(
                                                    controller: emailController,
                                                    autofocus: true,
                                                    autofillHints: [
                                                      AutofillHints.email,
                                                    ],
                                                    decoration: InputDecoration(
                                                      prefixIcon: const Icon(Icons.email_outlined),
                                                      labelText: 'Email',
                                                      labelStyle:
                                                          GoogleFonts.inter(
                                                            letterSpacing: 0.0,
                                                          ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: ColorsManger
                                                              .primaryBackground,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.0,
                                                            ),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color:
                                                                  ColorsManger
                                                                      .primary,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12.0,
                                                                ),
                                                          ),
                                                      errorBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: ColorsManger
                                                              .alternate,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.0,
                                                            ),
                                                      ),
                                                      focusedErrorBorder:
                                                          OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color: ColorsManger
                                                                  .alternate,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12.0,
                                                                ),
                                                          ),
                                                      filled: true,
                                                      fillColor: ColorsManger
                                                          .primaryBackground,
                                                    ),
                                                    style: GoogleFonts.inter(
                                                      letterSpacing: 0.0,
                                                    ),
                                                    keyboardType: TextInputType
                                                        .emailAddress,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty ||
                                                          !AppRegex.isEmailValid(
                                                            value,
                                                          )) {
                                                        return 'Please enter valid email';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    EdgeInsetsDirectional.fromSTEB(
                                                      0.0,
                                                      0.0,
                                                      0.0,
                                                      16.0,
                                                    ),
                                                child: Container(
                                                  width: double.infinity,
                                                  child: TextFormField(
                                                    controller: passwordController,
                                                    autofocus: true,
                                                    autofillHints: [
                                                      AutofillHints.password,
                                                    ],
                                                    obscureText:cubit.isPassword,
                                                    decoration: InputDecoration(
                                                      prefixIcon: const Icon(Icons.lock_outline),

                                                      labelText: 'Password',
                                                      labelStyle:
                                                          GoogleFonts.inter(
                                                            letterSpacing: 0.0,
                                                          ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: ColorsManger
                                                              .primaryBackground,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.0,
                                                            ),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color:
                                                                  ColorsManger
                                                                      .primary,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12.0,
                                                                ),
                                                          ),
                                                      errorBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: ColorsManger
                                                              .error,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.0,
                                                            ),
                                                      ),
                                                      focusedErrorBorder:
                                                          OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color:
                                                                  ColorsManger
                                                                      .error,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12.0,
                                                                ),
                                                          ),
                                                      filled: true,
                                                      fillColor: ColorsManger
                                                          .primaryBackground,
                                                      suffixIcon: IconButton(
                                                        onPressed: () {
                                                          cubit.changePasswordVisibility();
                                                        },
                                                        icon: Icon(cubit.suffixIcon),
                                                      ),
                                                    ),
                                                    style: GoogleFonts.inter(
                                                      letterSpacing: 0.0,
                                                    ),
                                                    validator: (value) {
                                                      if ( value == null || value.isEmpty) {
                                                        return 'please enter password';
                                                      }
                                                      else {
                                                        return null;
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                              LoadingButton(
                                                  text: 'Sign In',
                                                  controller: cubit.btnController,
                                                  onPressed: () {
                                                    FocusScope.of(context).requestFocus(FocusNode());
                                                    if (formKey.currentState!.validate()) {
                                                      cubit.login(
                                                          email: emailController.text,
                                                          password: passwordController.text);
                                                    } else {
                                                      cubit.btnController.error();
                                                      Future.delayed(const Duration(seconds: 3), () {
                                                        cubit.btnController.reset();
                                                      });
                                                    }
                                                  }
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Align(
                              alignment: AlignmentDirectional(0.0, -1.0),
                              child: Text(
                                'Powered by Double Click',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.styleScript(
                                  fontSize: 25,
                                  letterSpacing: 0.0,
                                ),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                'assets/images/3bb522e6-c73d-42ea-b903-8205085c8fbb.png',
                                width: 150.0,
                                height: 150.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
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
