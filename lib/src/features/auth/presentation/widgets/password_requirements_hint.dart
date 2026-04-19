import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/password_validation_policy.dart';

final class PasswordRequirementsHint extends StatelessWidget {
  const PasswordRequirementsHint({
    super.key,
    required this.currentPassword,
    required this.isFocused,
  });

  final String currentPassword;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final bool hasMissingRequirements =
        PasswordValidationPolicy.rules.validate(currentPassword) != null;
    if (!hasMissingRequirements) {
      return const SizedBox.shrink();
    }

    if (!isFocused && currentPassword.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 4),
          Text(
            context.l10n.tr(AppLocaleKeys.authPasswordRulesTitle),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          ...PasswordValidationPolicy.requirements.map((
            PasswordRequirementSpec requirement,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _PasswordRequirementRow(
                label: context.l10n.tr(requirement.labelKey),
                isSatisfied: requirement.isSatisfied(currentPassword),
              ),
            );
          }),
        ],
      ),
    );
  }
}

final class _PasswordRequirementRow extends StatelessWidget {
  const _PasswordRequirementRow({
    required this.label,
    required this.isSatisfied,
  });

  final String label;
  final bool isSatisfied;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color indicatorColor = isSatisfied
        ? colorScheme.tertiary
        : colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.check_circle_outline, color: indicatorColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: indicatorColor,
              fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.w400,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
