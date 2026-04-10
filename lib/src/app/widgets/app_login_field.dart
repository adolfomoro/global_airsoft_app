import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/widgets/app_text_field.dart';

final class AppLoginField extends StatelessWidget {
  const AppLoginField({
    super.key,
    required this.controller,
    this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      labelText: 'Username or Email',
      hintText: 'Enter your login',
      controller: controller,
      onChanged: onChanged,
      errorText: errorText,
      prefixIcon: const Icon(Icons.person_outline),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
    );
  }
}
