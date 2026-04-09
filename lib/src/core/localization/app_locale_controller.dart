import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_service.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';

final class AppLocaleController extends StateNotifier<Locale> {
  AppLocaleController({
    required AppLocaleService localeService,
    required Locale initialUiLocale,
  }) : _localeService = localeService,
       super(initialUiLocale);

  final AppLocaleService _localeService;
  String? _pendingServerLocaleTag;

  String get currentLanguageTag => AppLocalizations.toLanguageTag(state);

  bool get hasPendingServerLocaleChange => _pendingServerLocaleTag != null;

  Future<void> setLocale(Locale locale) async {
    final Locale resolved = AppLocalizations.resolveFromPreferred(<Locale>[
      locale,
    ]);
    if (state == resolved) {
      return;
    }

    final Locale previous = state;
    state = resolved;
    try {
      await _localeService.saveUiLocale(resolved);
    } catch (error, stackTrace) {
      state = previous;
      AppLogger.instance.error(
        'Failed to persist selected UI locale',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> syncFromServerContentLanguage(String? contentLanguage) async {
    final String? normalized = AppLocalizations.normalizeLanguageTag(
      contentLanguage,
    );
    if (normalized == null) {
      return;
    }

    final String currentUiTag = AppLocalizations.toLanguageTag(state);
    if (normalized == currentUiTag) {
      return;
    }

    try {
      await _localeService.saveUiLocale(
        AppLocalizations.resolveFromLanguageTag(normalized),
      );
      if (currentUiTag == normalized) {
        _pendingServerLocaleTag = null;
      } else {
        _pendingServerLocaleTag = normalized;
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Failed to persist server content-language locale',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> forceApplyServerLocaleIfPending() async {
    final String? pending = _pendingServerLocaleTag;
    if (pending == null) {
      return false;
    }

    final Locale next = AppLocalizations.resolveFromLanguageTag(pending);
    if (next == state) {
      _pendingServerLocaleTag = null;
      return false;
    }

    state = next;
    _pendingServerLocaleTag = null;
    return true;
  }
}
