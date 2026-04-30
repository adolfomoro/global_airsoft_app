import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/validation/validation_mapping_result.dart';

extension AuthPresentationRefX on WidgetRef {
  Future<void> applyPendingAuthLocale() {
    return read(
      appLocaleControllerProvider.notifier,
    ).forceApplyServerLocaleIfPending();
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
