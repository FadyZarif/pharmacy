import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../features/login/data/models/user_model.dart';


String? uid ;

late bool isLogged;
late UserModel currentUser;
late FirebaseApp app;

Future<bool> checkIsLogged() async {

  if (FirebaseAuth.instance.currentUser == null) {
    isLogged = false;
    return false;
  } else {
    uid = FirebaseAuth.instance.currentUser?.uid;
    isLogged = true;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    currentUser = UserModel.fromJson(doc.data()!);

    return true;
  }
}




void navigateTo(context,widget){
  Navigator.push(context, MaterialPageRoute(builder: (context)=>widget));
}

void navigateToReplacement(context,widget){
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>widget));
}

Future<void> defToast2({
  required BuildContext context,
  required String msg,
  required DialogType dialogType,
  int? sec,

})async{
  await AwesomeDialog(
    context: context,
    animType: AnimType.scale,
    autoHide: Duration(seconds: sec??2),
    title: msg,
    dialogType: dialogType,

  ).show();
}

class CenterTransition extends PageRouteBuilder {
  final Widget page;

  CenterTransition(this.page)
      : super(
    pageBuilder: (context, animation, anotherAnimation) => page,
    transitionDuration: const Duration(milliseconds: 1000),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, anotherAnimation, child) {
      animation = CurvedAnimation(
          curve: Curves.fastLinearToSlowEaseIn,
          parent: animation,
          reverseCurve: Curves.fastOutSlowIn);
      return Align(
        alignment: Alignment.center,
        child: SizeTransition(
          axis: Axis.horizontal,
          sizeFactor: animation,
          axisAlignment: 0,
          child: page,
        ),
      );
    },
  );
}
class BottomScaleTransition extends PageRouteBuilder {
  final Widget page;

  BottomScaleTransition(this.page)
      : super(
    pageBuilder: (context, animation, anotherAnimation) => page,
    transitionDuration: const Duration(milliseconds: 1000),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, anotherAnimation, child) {
      animation = CurvedAnimation(
          curve: Curves.fastLinearToSlowEaseIn,
          parent: animation,
          reverseCurve: Curves.fastOutSlowIn);
      return ScaleTransition(
        alignment: Alignment.bottomCenter,
        scale: animation,
        child: child,
      );
    },
  );
}


