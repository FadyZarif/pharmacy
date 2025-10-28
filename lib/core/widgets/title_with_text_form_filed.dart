// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../themes/colors.dart';
// import 'app_text_form_field.dart';
//
// class TitleWithTextFormFiled extends StatelessWidget {
//   final String labelText;
//   final Widget prefixIcon;
//   final Widget? suffixIcon;
//   final String? Function(String?)? validator;
//   final TextInputType? keyboardType;
//   final int? maxLength;
//   final int? maxLines;
//   final List<TextInputFormatter>? listTextInputFormatter;
//   final TextEditingController textEditingController;
//   final void Function(String)? onChanged;
//   final bool? readOnly;
//
//   const TitleWithTextFormFiled(
//       {super.key,
//         required this.labelText,
//         required this.prefixIcon,
//         this.suffixIcon,
//         this.validator,
//         this.keyboardType,
//         this.maxLength,
//         this.listTextInputFormatter,
//         required this.textEditingController, this.onChanged, this.maxLines, this.readOnly});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       spacing: 10,
//       children: [
//         Text(
//           labelText,
//           style: TextStyle(
//               fontSize: 14,
//               color: ColorsManger.primary,
//               fontWeight: FontWeight.bold),
//         ),
//         AppTextFormField(
//           filled: true,
//           fillColor: ColorsManger.primary.withValues(alpha: 0.1),
//           borderSide: BorderSide.none,
//           focusedBorderSide: BorderSide(color: ColorsManger.primary),
//           prefixIcon: prefixIcon,
//           suffixIcon: suffixIcon,
//           validator: validator,
//           keyboardType: keyboardType,
//           maxLength: maxLength,
//           listTextInputFormatter: listTextInputFormatter,
//           textEditingController: textEditingController,
//           onChanged: onChanged,
//           maxLines: maxLines,
//           readOnly: readOnly??false,
//
//         ),
//       ],
//     );
//   }
// }