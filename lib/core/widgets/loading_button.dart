import 'package:flutter/material.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../themes/colors.dart';


class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, required this.controller, required this.onPressed, required this.text});
  final RoundedLoadingButtonController controller;
  final void Function() onPressed;
  final String text;
  @override
  Widget build(BuildContext context) {
    return RoundedLoadingButton(
      color: ColorsManger.primary,
      completionDuration: const Duration(seconds: 3),
      resetDuration: const Duration(seconds: 3),
      resetAfterDuration: false,
      controller: controller,
      onPressed: onPressed,
      successColor: Colors.green,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
