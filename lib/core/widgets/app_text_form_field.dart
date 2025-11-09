import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../themes/colors.dart';



class AppTextFormField extends StatelessWidget {
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? focusedBorder;
  final InputBorder? enabledBorder;
  final TextStyle? hintStyle;
  final String? hintText;
  final String? labelText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool? obscureText;
  final TextStyle? style;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Color? fillColor;
  final bool? isArabic;
  final List<String>? autofillHints;
  final Function()? onTap;
  final bool? readOnly;




  const AppTextFormField({
    super.key,
    this.contentPadding,
    this.focusedBorder,
    this.enabledBorder,
    this.hintStyle,
    this.hintText,
    this.suffixIcon,
    this.obscureText,
    this.style,
    required this.controller,
    this.validator, this.prefixIcon, this.labelText, this.textInputAction, this.keyboardType, this.maxLength, this.inputFormatters, this.fillColor, this.isArabic, this.autofillHints, this.onTap, this.readOnly, this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      expands: false,
      controller: controller,
      onTap: onTap,
      readOnly: readOnly??false,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: obscureText == true ? 1 : maxLines,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      textDirection: isArabic == true ? TextDirection.rtl : TextDirection.ltr,

      decoration: InputDecoration(
        isDense: true,
        filled: fillColor != null ,
        fillColor:fillColor?? ColorsManger.lightestGrey,
        prefixIcon: prefixIcon,
        labelText:labelText,
        contentPadding: contentPadding ??
            EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        focusedBorder: focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
              const BorderSide(color: ColorsManger.primary, width: 1.3),
            ),
        enabledBorder: enabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
              const BorderSide(color: ColorsManger.lighterGrey, width: 1.3),
            ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        hintStyle: hintStyle ?? TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ColorsManger.lightGrey,
        ),
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
      obscureText: obscureText ?? false,
      style: style ?? TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ColorsManger.primary,
      ),
      validator: validator,
    );
  }
}
