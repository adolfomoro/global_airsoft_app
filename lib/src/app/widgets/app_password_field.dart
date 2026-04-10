import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/widgets/app_text_field.dart';

final class AppPasswordField extends StatelessWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    this.onChanged,
    this.errorText,
    this.textInputAction = TextInputAction.done,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      labelText: 'Password',
      controller: controller,
      onChanged: onChanged,
      errorText: errorText,
      obscureText: true,
      prefixIcon: const Icon(Icons.lock_outline),
      keyboardType: TextInputType.visiblePassword,
      textInputAction: textInputAction,
    );
  }
}
