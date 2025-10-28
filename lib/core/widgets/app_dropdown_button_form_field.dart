import 'package:flutter/material.dart';
import 'package:pharmacy/core/themes/colors.dart';



class AppDropdownButtonFormField<T> extends StatelessWidget {
  final Widget? iconArrow;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<DropdownMenuItem<T>>? items;
  final String? Function(T?)? validator;
  final T? value;
  final void Function(T?)? onChanged;
  final bool autofocus;
  final Color? fillColor;
  final String? labelText;
  final TextStyle? hintStyle;
  final String? hintText;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? focusedBorder;
  final InputBorder? enabledBorder;

  const AppDropdownButtonFormField({
    super.key,
    this.iconArrow,
    this.prefixIcon,
    this.items,
    this.validator,
    this.value,
    this.onChanged,
    this.autofocus = false, this.suffixIcon, this.fillColor, this.labelText, this.hintStyle, this.hintText, this.contentPadding, this.focusedBorder, this.enabledBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      shadowColor: ColorsManger.primary.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ColorsManger.primary.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: DropdownButtonFormField<T>(

          autofocus: autofocus,
          value: value,
          isExpanded: true,
          icon: iconArrow ?? const Icon(Icons.arrow_drop_down),
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
          items: items,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            overflow: TextOverflow.ellipsis,
          ),
          validator: validator,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
