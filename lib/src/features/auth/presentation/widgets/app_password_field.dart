import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_text_field.dart';

final class AppPasswordField extends StatelessWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    this.focusNode,
    this.labelText = 'Password',
    this.onChanged,
    this.onFieldSubmitted,
    this.errorText,
    this.validator,
    this.isRequired = false,
    this.textInputAction = TextInputAction.done,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final String? errorText;
  final String? Function(String?)? validator;
  final bool isRequired;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      labelText: labelText,
      isRequired: isRequired,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      errorText: errorText,
      validator: validator,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: textInputAction,
    );
  }
}


