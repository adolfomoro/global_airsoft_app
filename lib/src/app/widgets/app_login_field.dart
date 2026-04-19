import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/widgets/app_text_field.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';

final class AppLoginField extends StatelessWidget {
  const AppLoginField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onFieldSubmitted,
    this.errorText,
    this.validator,
    this.isRequired = false,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final String? errorText;
  final String? Function(String?)? validator;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      labelText: context.l10n.tr(AppLocaleKeys.authLoginIdentifierLabel),
      isRequired: isRequired,
      controller: controller,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      errorText: errorText,
      validator: validator,
      prefixIcon: const Icon(Icons.person_outline),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[
        AutofillHints.username,
        AutofillHints.email,
      ],
    );
  }
}
