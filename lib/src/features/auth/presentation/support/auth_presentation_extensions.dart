import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/validation/validation_mapping_result.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';

extension AuthPresentationRefX on WidgetRef {
  Future<void> applyPendingAuthLocale() {
    return read(
      appLocaleControllerProvider.notifier,
    ).forceApplyServerLocaleIfPending();
  }

  Future<void> completeAuthenticatedSession() async {
    await applyPendingAuthLocale();
    read(isAuthenticatedProvider.notifier).setAuthenticated();
  }
}

extension ValidationMappingResultX on ValidationMappingResult {
  String? get firstMeaningfulGlobalError {
    for (final String error in globalErrors) {
      final String trimmed = error.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return null;
  }
}

extension AuthPresentationContextX on BuildContext {
  void showLocalizedErrorSnackBar(String localizationKey, {Object? source}) {
    showErrorSnackBar(l10n.tr(localizationKey), source: source);
  }
}
