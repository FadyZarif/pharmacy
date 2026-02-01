import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/features/request/data/services/coverage_shift_service.dart';

import '../../features/user/data/models/user_model.dart';



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
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    currentUser = UserModel.fromJson(doc.data()!);

    // Check if user is active
    if (!currentUser.isActive) {
      // Sign out inactive user
      await FirebaseAuth.instance.signOut();
      isLogged = false;
      return false;
    }

    isLogged = true;

    // Check if user has coverage shift today
    if (!currentUser.isManagement) {
      try {
        final coverageShiftService = getIt<CoverageShiftService>();
        final tempBranch = await coverageShiftService.getTemporaryBranch(currentUser.uid);

        if (tempBranch != null) {
          // Apply temporary branch for today
          currentUser.currentBranch = tempBranch;
        }
      } catch (e) {
        print('Error checking coverage shift: $e');
      }
    }

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
  // AwesomeDialog uses Rive animations which can crash on web in some setups.
  // For web, fallback to a simple SnackBar to keep the app stable.
  if (kIsWeb) {
    final color = switch (dialogType) {
      DialogType.success => Colors.green,
      DialogType.error => Colors.red,
      DialogType.warning => Colors.orange,
      DialogType.info => Colors.blue,
      DialogType.question => Colors.purple,
      _ => ColorsManger.primary,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: Duration(seconds: sec ?? 2),
      ),
    );
    return;
  }

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


