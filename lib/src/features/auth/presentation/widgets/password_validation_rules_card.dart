import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/password_validation_rules_output_dto.dart';

class PasswordValidationRulesCard extends StatelessWidget {
  const PasswordValidationRulesCard({
    this.rulesAsyncValue,
    this.currentPassword = '',
    super.key,
  });

  final AsyncValue<PasswordValidationRulesOutputDto>? rulesAsyncValue;
  final String currentPassword;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PasswordValidationRulesOutputDto> effectiveRulesAsync =
        rulesAsyncValue ??
        const AsyncValue<PasswordValidationRulesOutputDto>.loading();

    return effectiveRulesAsync.when(
      loading: () => _PasswordRulesLoadingCard(
        loadingLabel: context.l10n.tr(AppLocaleKeys.authPasswordRulesLoading),
      ),
      error: (Object error, StackTrace stackTrace) => const SizedBox.shrink(),
      data: (PasswordValidationRulesOutputDto rules) =>
          _PasswordRulesLoadedCard(
            title: context.l10n.tr(AppLocaleKeys.authPasswordRulesTitle),
            rules: rules,
            currentPassword: currentPassword,
          ),
    );
  }
}

class _PasswordRulesLoadingCard extends StatelessWidget {
  const _PasswordRulesLoadingCard({required this.loadingLabel});

  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return _BaseRulesCard(
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(loadingLabel)),
        ],
      ),
    );
  }
}

class _PasswordRulesLoadedCard extends StatelessWidget {
  const _PasswordRulesLoadedCard({
    required this.title,
    required this.rules,
    required this.currentPassword,
  });

  final String title;
  final PasswordValidationRulesOutputDto rules;
  final String currentPassword;

  @override
  Widget build(BuildContext context) {
    final String password = currentPassword;

    final List<_RuleItemData> items = <_RuleItemData>[
      if (rules.requiredLength > 0)
        _RuleItemData(
          text: context.l10n.trArgs(
            AppLocaleKeys.withPluralSuffix(
              baseKey: AppLocaleKeys.authPasswordRulesMinimumLength,
              isSingular: rules.requiredLength == 1,
            ),
            args: <String, Object?>{'min': rules.requiredLength},
          ),
          isSatisfied: password.length >= rules.requiredLength,
        ),
      if (rules.requiredUniqueChars > 0)
        _RuleItemData(
          text: context.l10n.trArgs(
            AppLocaleKeys.withPluralSuffix(
              baseKey: AppLocaleKeys.authPasswordRulesUniqueCharacters,
              isSingular: rules.requiredUniqueChars == 1,
            ),
            args: <String, Object?>{'min': rules.requiredUniqueChars},
          ),
          isSatisfied:
              password.runes.toSet().length >= rules.requiredUniqueChars,
        ),
      if (rules.requireDigit)
        _RuleItemData(
          text: context.l10n.tr(AppLocaleKeys.authPasswordRulesRequireDigit),
          isSatisfied: RegExp(r'.*\d.*').hasMatch(password),
        ),
      if (rules.requireLowercase)
        _RuleItemData(
          text: context.l10n.tr(
            AppLocaleKeys.authPasswordRulesRequireLowercase,
          ),
          isSatisfied: RegExp(r'.*[a-z].*').hasMatch(password),
        ),
      if (rules.requireUppercase)
        _RuleItemData(
          text: context.l10n.tr(
            AppLocaleKeys.authPasswordRulesRequireUppercase,
          ),
          isSatisfied: RegExp(r'.*[A-Z].*').hasMatch(password),
        ),
      if (rules.requireNonAlphanumeric)
        _RuleItemData(
          text: context.l10n.tr(
            AppLocaleKeys.authPasswordRulesRequireNonAlphanumeric,
          ),
          isSatisfied: RegExp(r'.*[^a-zA-Z0-9].*').hasMatch(password),
        ),
      if (rules.requiredLength <= 0 &&
          rules.requiredUniqueChars <= 0 &&
          !rules.requireNonAlphanumeric &&
          !rules.requireDigit &&
          !rules.requireLowercase &&
          !rules.requireUppercase)
        _RuleItemData(
          text: context.l10n.tr(
            AppLocaleKeys.authPasswordRulesNoAdditionalRequirements,
          ),
          isSatisfied: true,
        ),
    ];
    final int satisfiedCount = items.where((_RuleItemData item) {
      return item.isSatisfied;
    }).length;
    final bool hasStartedTyping = password.trim().isNotEmpty;
    final List<_RuleItemData> orderedItems = hasStartedTyping
        ? <_RuleItemData>[
            ...items.where((_RuleItemData item) => !item.isSatisfied),
            ...items.where((_RuleItemData item) => item.isSatisfied),
          ]
        : items;

    return _BaseRulesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: Text(
                  '$satisfiedCount/${items.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 96),
            child: SingleChildScrollView(
              child: Column(
                children: orderedItems
                    .map((_RuleItemData item) {
                      return _RuleLine(
                        text: item.text,
                        isSatisfied: item.isSatisfied,
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleItemData {
  const _RuleItemData({required this.text, required this.isSatisfied});

  final String text;
  final bool isSatisfied;
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text, required this.isSatisfied});

  final String text;
  final bool isSatisfied;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).colorScheme.tertiary;
    final Color inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isSatisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isSatisfied ? activeColor : inactiveColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSatisfied ? activeColor : inactiveColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BaseRulesCard extends StatelessWidget {
  const _BaseRulesCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(padding: const EdgeInsets.all(6), child: child),
    );
  }
}
