import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../../../core/helpers/constants.dart';
import '../../../core/services/notification_service.dart';
import 'login_states.dart';



class LoginCubit extends Cubit<LoginStates>{

  LoginCubit() : super(LoginInitialState());


  //SignInModel? SignInModel ;

  void login({required String email , required String password}){
    emit(LoginLoadingState());

    FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password).then((value) async {
      uid = value.user!.uid;

      // Check if user is logged and active
      bool userIsActive = await checkIsLogged();

      if (!userIsActive || !isLogged) {
        // User is inactive, sign them out and show error
        await FirebaseAuth.instance.signOut();
        btnController.error();
        emit(LoginErrorState('Your account has been deactivated. Please contact your administrator.'));
        Future.delayed(const Duration(seconds: 3), () {
          btnController.reset();
        });
        return;
      }

      btnController.success();

      // Update FCM token after login
      await NotificationService().updateUserToken(currentUser.uid);

      emit(LoginSuccessState());
      Future.delayed(const Duration(seconds: 3), () {
        btnController.reset();
      });
    }).catchError((error){
      btnController.error();
      emit(LoginErrorState(error.message));
      Future.delayed(const Duration(seconds: 3), () {
        btnController.reset();
      });
    });
  }

  bool isPassword = true;
  IconData suffixIcon = Icons.visibility;

  void changePasswordVisibility(){
    emit(LoginChangeVisibilityState());
    isPassword = !isPassword;
    if(isPassword) {
      suffixIcon = Icons.visibility;
    } else {
      suffixIcon = Icons.visibility_off;
    }
  }

  final RoundedLoadingButtonController btnController =
  RoundedLoadingButtonController();

}