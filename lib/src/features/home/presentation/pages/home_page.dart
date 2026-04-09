import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference.dart';
import 'package:global_airsoft_app/src/app/theme/theme_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/home/presentation/providers/home_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String environmentLabel = ref.watch(startupEnvironmentLabelProvider);
    final AppThemePreference selectedThemePreference = ref.watch(
      selectedThemePreferenceProvider,
    );
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool hasPendingServerLocaleChange = ref.watch(
      hasPendingServerLocaleChangeProvider,
    );
    final String selectedThemeLabel = l10n.tr(
      selectedThemePreference == AppThemePreference.dark
          ? AppLocaleKeys.themeDarkLabel
          : AppLocaleKeys.themeLightLabel,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.tr(AppLocaleKeys.appTitle)),
        actions: <Widget>[
          IconButton(
            tooltip: isDark
                ? l10n.tr(AppLocaleKeys.switchToLight)
                : l10n.tr(AppLocaleKeys.switchToDark),
            onPressed: () {
              ref.read(themePreferenceControllerProvider.notifier).toggle();
            },
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? <Color>[AppColors.background, AppColors.backgroundMid]
                : <Color>[AppColors.surface, AppColors.surfaceVariant],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacing2xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.maxContentWidth,
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacing2xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          l10n.tr(AppLocaleKeys.homeTitle),
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spacingSm),
                        Text(
                          l10n.tr(AppLocaleKeys.homeSubtitle),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spacingLg),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingMd,
                            vertical: AppDimensions.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusPill,
                            ),
                          ),
                          child: Text(
                            l10n
                                .tr(AppLocaleKeys.environmentLabel)
                                .replaceAll('{environment}', environmentLabel),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXl),
                        Text(
                          l10n
                              .tr(AppLocaleKeys.themeLabel)
                              .replaceAll('{theme}', selectedThemeLabel),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        Text(
                          hasPendingServerLocaleChange
                              ? l10n.tr(AppLocaleKeys.serverLanguagePending)
                              : l10n.tr(AppLocaleKeys.noPendingLanguage),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        FilledButton(
                          onPressed: () {
                            ref
                                .read(
                                  themePreferenceControllerProvider.notifier,
                                )
                                .toggle();
                          },
                          child: Text(
                            isDark
                                ? l10n.tr(AppLocaleKeys.useLightTheme)
                                : l10n.tr(AppLocaleKeys.useDarkTheme),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        OutlinedButton(
                          onPressed: () async {
                            final bool changed = await ref
                                .read(appLocaleControllerProvider.notifier)
                                .forceApplyServerLocaleIfPending();

                            if (!context.mounted) {
                              return;
                            }

                            final String message = changed
                                ? l10n.tr(AppLocaleKeys.languageApplied)
                                : l10n.tr(AppLocaleKeys.noPendingLanguage);
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          },
                          child: Text(
                            l10n.tr(AppLocaleKeys.forceApplyServerLanguage),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
