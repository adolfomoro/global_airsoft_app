import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations._(
    this.locale,
    this._localizedValues, {
    Map<String, String> englishValues = const <String, String>{},
  }) : _englishValues = englishValues;

  final Locale locale;
  final Map<String, String> _localizedValues;
  final Map<String, String> _englishValues;

  static const Locale fallbackLocale = Locale('en');
  static final String _fallbackLanguageTag = _buildLanguageTag(fallbackLocale);

  static const List<Locale> supportedLocales = <Locale>[
    fallbackLocale,
    Locale('pt', 'BR'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );

    return localizations ??
        AppLocalizations._(fallbackLocale, <String, String>{});
  }

  String tr(String key) {
    final String? primary = _localizedValues[key];
    if (primary != null && primary.trim().isNotEmpty) {
      return primary;
    }

    final bool isEnglishLocale =
        AppLocalizations.toLanguageTag(locale) == _fallbackLanguageTag;

    if (!isEnglishLocale) {
      final String? englishValue = _englishValues[key];
      if (englishValue != null && englishValue.trim().isNotEmpty) {
        return englishValue;
      }
    }

    return key;
  }

  String trArgs(
    String key, {
    Map<String, Object?> args = const <String, Object?>{},
  }) {
    String value = tr(key);

    for (final MapEntry<String, Object?> entry in args.entries) {
      final String argKey = entry.key;
      final Object? argValue = entry.value;
      value = value.replaceAll('{$argKey}', argValue?.toString() ?? '');
    }

    return value;
  }

  static Locale resolveFromPreferred(List<Locale>? preferredLocales) {
    if (preferredLocales == null || preferredLocales.isEmpty) {
      return fallbackLocale;
    }

    for (final Locale locale in preferredLocales) {
      final Locale? resolved = _matchSupportedLocale(locale);
      if (resolved != null) {
        return resolved;
      }
    }

    return fallbackLocale;
  }

  static Locale resolveFromLanguageTag(String? rawTag) {
    final String? normalized = normalizeLanguageTag(rawTag);
    if (normalized == null) {
      return fallbackLocale;
    }

    final Locale? locale = _localeFromLanguageTag(normalized);
    return locale ?? fallbackLocale;
  }

  static String toLanguageTag(Locale locale) {
    final Locale resolved = _matchSupportedLocale(locale) ?? fallbackLocale;
    return _buildLanguageTag(resolved);
  }

  static String? normalizeLanguageTag(String? rawTag) {
    if (rawTag == null) {
      return null;
    }

    final String trimmed = rawTag.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final String firstToken = trimmed
        .split(',')
        .first
        .split(';')
        .first
        .trim()
        .replaceAll('_', '-');

    if (firstToken.isEmpty) {
      return null;
    }

    final List<String> parts = firstToken.split('-');
    final String languageCode = parts.first.toLowerCase();
    final String? countryCode = parts.length > 1
        ? parts[1].toUpperCase()
        : null;

    final Locale candidate = Locale.fromSubtags(
      languageCode: languageCode,
      countryCode: countryCode,
    );

    final Locale? resolved = _matchSupportedLocale(candidate);
    if (resolved == null) {
      return null;
    }

    return _buildLanguageTag(resolved);
  }

  static Locale? _matchSupportedLocale(Locale locale) {
    final String languageCode = locale.languageCode.toLowerCase();

    for (final Locale supported in supportedLocales) {
      if (_isSameLocale(locale, supported)) {
        return supported;
      }
    }

    Locale? firstSameLanguage;
    for (final Locale supported in supportedLocales) {
      if (supported.languageCode.toLowerCase() == languageCode) {
        firstSameLanguage ??= supported;
      }
    }

    if (firstSameLanguage == null) {
      return null;
    }

    final String? localeCountry = locale.countryCode?.toUpperCase();
    if (localeCountry != null && localeCountry.isNotEmpty) {
      for (final Locale candidate in supportedLocales) {
        if (candidate.languageCode.toLowerCase() != languageCode) {
          continue;
        }

        final String? candidateCountry = candidate.countryCode?.toUpperCase();
        if (candidateCountry == localeCountry) {
          return candidate;
        }
      }
    }

    return firstSameLanguage;
  }

  static Locale? _localeFromLanguageTag(String tag) {
    final List<String> parts = tag.split('-');
    final String languageCode = parts.first.toLowerCase();
    final String? countryCode = parts.length > 1
        ? parts[1].toUpperCase()
        : null;

    return _matchSupportedLocale(
      Locale.fromSubtags(languageCode: languageCode, countryCode: countryCode),
    );
  }

  static String _buildLanguageTag(Locale locale) {
    final String languageCode = locale.languageCode.toLowerCase();
    final String? countryCode = locale.countryCode?.toUpperCase();
    if (countryCode == null || countryCode.isEmpty) {
      return languageCode;
    }
    return '$languageCode-$countryCode';
  }

  static bool _isSameLocale(Locale left, Locale right) {
    return left.languageCode.toLowerCase() ==
            right.languageCode.toLowerCase() &&
        (left.countryCode?.toUpperCase() ?? '') ==
            (right.countryCode?.toUpperCase() ?? '');
  }

  static String _assetCodeFromLocale(Locale locale) {
    return toLanguageTag(locale);
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  static final Map<String, Future<Map<String, String>>> _localeValuesCache =
      <String, Future<Map<String, String>>>{};

  @override
  bool isSupported(Locale locale) {
    final Locale resolved = AppLocalizations.resolveFromPreferred(<Locale>[
      locale,
    ]);
    return AppLocalizations.supportedLocales.contains(resolved);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final Locale resolved = AppLocalizations.resolveFromPreferred(<Locale>[
      locale,
    ]);
    final Map<String, String> resolvedValues = await _loadValuesForLocale(
      resolved,
    );

    final bool isEnglishLocale =
        AppLocalizations.toLanguageTag(resolved) ==
        AppLocalizations._fallbackLanguageTag;

    final Map<String, String> englishValues = isEnglishLocale
        ? resolvedValues
        : await _loadValuesForLocale(AppLocalizations.fallbackLocale);

    return AppLocalizations._(
      resolved,
      resolvedValues,
      englishValues: englishValues,
    );
  }

  @override
  bool shouldReload(covariant AppLocalizationsDelegate old) {
    return false;
  }

  Map<String, String> _toStringMap(Object? decoded) {
    if (decoded is! Map<String, dynamic>) {
      return <String, String>{};
    }

    final Map<String, String> map = <String, String>{};
    for (final MapEntry<String, dynamic> entry in decoded.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;
      if (value is String) {
        map[key] = value;
      }
    }
    return map;
  }

  Future<Map<String, String>> _loadValuesForLocale(Locale locale) async {
    final String assetCode = AppLocalizations._assetCodeFromLocale(locale);

    return _localeValuesCache.putIfAbsent(assetCode, () async {
      try {
        final String jsonString = await rootBundle.loadString(
          'assets/i18n/$assetCode.json',
        );
        final Object? decoded = json.decode(jsonString);
        return _toStringMap(decoded);
      } catch (error) {
        final Future<Map<String, String>>? pendingLoad = _localeValuesCache
            .remove(assetCode);
        if (pendingLoad != null) {
          unawaited(pendingLoad);
        }
        assert(() {
          debugPrint('Localization load failed for $assetCode: $error');
          return true;
        }());
        return <String, String>{};
      }
    });
  }
}

extension AppLocalizationsBuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
