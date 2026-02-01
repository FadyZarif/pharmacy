import 'package:flutter/material.dart';

import '../themes/colors.dart';
import 'app_dropdown_button_form_field.dart';

class TitleWithDropdownButtonFormField extends StatelessWidget {
  final String labelText;
  final Widget? iconArrow;
  final Widget? prefixIcon;
  final List<DropdownMenuItem<String>> items;
  final String? Function(String?)? validator;
  final String? value;
  final void Function(String?)? onChanged;

  const TitleWithDropdownButtonFormField({
    super.key,
    this.iconArrow,
    this.prefixIcon,
    required this.items,
    this.onChanged,
    this.validator,
    required this.labelText,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          labelText,
          style: TextStyle(
              fontSize: 14,
              color: ColorsManger.primary,
              fontWeight: FontWeight.bold),
        ),
        AppDropdownButtonFormField(
          iconArrow: iconArrow,
          prefixIcon: prefixIcon,
          value: value,
          items: items,
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}