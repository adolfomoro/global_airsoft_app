import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/app/widgets/app_field_loading_indicator.dart';
import 'package:global_airsoft_app/src/app/widgets/app_text_field.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/localization/app_validation_localizations.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/check_username_availability_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/username_validation.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';

enum UsernameAvailabilityStatus {
  idle,
  waiting,
  checking,
  available,
  unavailable,
  failed,
}

final class UsernameAvailabilityField extends ConsumerStatefulWidget {
  const UsernameAvailabilityField({
    required this.controller,
    super.key,
    this.errorText,
    this.onChanged,
    this.onFieldSubmitted,
    this.onAvailabilityChanged,
    this.textInputAction = TextInputAction.next,
    this.debounceDuration = const Duration(milliseconds: 650),
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<UsernameAvailabilityStatus>? onAvailabilityChanged;
  final TextInputAction textInputAction;
  final Duration debounceDuration;

  @override
  ConsumerState<UsernameAvailabilityField> createState() =>
      _UsernameAvailabilityFieldState();
}

class _UsernameAvailabilityFieldState
    extends ConsumerState<UsernameAvailabilityField> {
  static final ValidationRuleSet _usernameValidationRules =
      UsernameValidation.rules;

  Timer? _debounceTimer;
  UsernameAvailabilityStatus _status = UsernameAvailabilityStatus.idle;
  List<String> _suggestions = const <String>[];
  String? _unavailableUsername;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _scheduleAvailabilityCheck(widget.controller.text);
    });
  }

  @override
  void didUpdateWidget(covariant UsernameAvailabilityField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _cancelPendingWork();
      _scheduleAvailabilityCheck(widget.controller.text);
    }
  }

  @override
  void dispose() {
    _cancelPendingWork();
    super.dispose();
  }

  void _cancelPendingWork() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _requestSerial++;
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    _scheduleAvailabilityCheck(value);
  }

  void _scheduleAvailabilityCheck(String value, {bool immediate = false}) {
    _debounceTimer?.cancel();

    final String username = _normalizeUsername(value);
    final ValidationFailure? failure = _usernameValidationRules.validate(
      username,
    );

    _requestSerial++;
    _unavailableUsername = null;
    _suggestions = const <String>[];

    if (failure != null) {
      _setStatus(UsernameAvailabilityStatus.idle);
      return;
    }

    _setStatus(UsernameAvailabilityStatus.waiting);

    if (immediate) {
      _checkAvailability(username);
      return;
    }

    _debounceTimer = Timer(widget.debounceDuration, () {
      _checkAvailability(username);
    });
  }

  Future<void> _checkAvailability(String username) async {
    final int requestId = ++_requestSerial;
    _setStatus(UsernameAvailabilityStatus.checking);

    try {
      final CheckUsernameAvailabilityOutputDto result = await ref
          .read(authServiceProvider)
          .checkUsernameAvailability(username);

      if (!mounted || requestId != _requestSerial) {
        return;
      }

      if (_normalizeUsername(widget.controller.text) != username) {
        return;
      }

      _suggestions = result.suggestions;
      _unavailableUsername = result.isAvailable ? null : username;
      _setStatus(
        result.isAvailable
            ? UsernameAvailabilityStatus.available
            : UsernameAvailabilityStatus.unavailable,
      );
    } catch (_) {
      if (!mounted || requestId != _requestSerial) {
        return;
      }

      _suggestions = const <String>[];
      _unavailableUsername = null;
      _setStatus(UsernameAvailabilityStatus.failed);
    }
  }

  void _setStatus(UsernameAvailabilityStatus status) {
    final bool didStatusChange = _status != status;

    setState(() {
      _status = status;
    });
    if (didStatusChange) {
      widget.onAvailabilityChanged?.call(status);
    }
  }

  void _applySuggestion(String suggestion) {
    widget.controller.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
    widget.onChanged?.call(suggestion);
    _scheduleAvailabilityCheck(suggestion, immediate: true);
  }

  String? _validateUsername(String? value) {
    final String username = _normalizeUsername(value ?? '');
    final ValidationFailure? failure = _usernameValidationRules.validate(
      username,
    );
    if (failure != null) {
      return context.resolveValidationMessage(failure);
    }

    if (_status == UsernameAvailabilityStatus.unavailable &&
        _unavailableUsername == username) {
      return context.l10n.tr(AppLocaleKeys.authUsernameUnavailable);
    }

    return null;
  }

  String _normalizeUsername(String value) {
    return value.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasExternalError = widget.errorText?.trim().isNotEmpty == true;
    final bool isChecking = _status == UsernameAvailabilityStatus.checking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          labelText: context.l10n.tr(AppLocaleKeys.authUsernameLabel),
          controller: widget.controller,
          onChanged: _handleChanged,
          errorText: widget.errorText,
          isRequired: _usernameValidationRules.hasRequiredRule,
          keyboardType: TextInputType.text,
          textInputAction: widget.textInputAction,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          suffixIcon: isChecking
              ? AppFieldLoadingIndicator(
                  semanticsLabel: context.l10n.tr(
                    AppLocaleKeys.authUsernameChecking,
                  ),
                )
              : null,
          onFieldSubmitted: widget.onFieldSubmitted,
          validator: _validateUsername,
        ),
        if (!hasExternalError && !isChecking) ...<Widget>[
          const SizedBox(height: AppDimensions.spacingSm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _UsernameFeedback(
              key: ValueKey<String>(
                '${_status.name}:${_suggestions.join('|')}',
              ),
              status: _status,
              suggestions: _suggestions,
              onSuggestionSelected: _applySuggestion,
            ),
          ),
        ],
      ],
    );
  }
}

class _UsernameFeedback extends StatelessWidget {
  const _UsernameFeedback({
    required this.status,
    required this.suggestions,
    required this.onSuggestionSelected,
    super.key,
  });

  final UsernameAvailabilityStatus status;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final _FeedbackContent content = _resolveContent(context, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (status == UsernameAvailabilityStatus.checking)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: content.color,
                ),
              )
            else
              Icon(content.icon, size: 18, color: content.color),
            const SizedBox(width: AppDimensions.spacingXs),
            Expanded(
              child: Text(
                content.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: content.color,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        if (status == UsernameAvailabilityStatus.unavailable &&
            suggestions.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppDimensions.spacingSm),
          Row(
            children: <Widget>[
              Text(
                context.l10n.tr(AppLocaleKeys.authUsernameSuggestionsLabel),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingXs),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: suggestions
                        .map((String suggestion) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: AppDimensions.spacingXs,
                            ),
                            child: ActionChip(
                              label: Text(suggestion),
                              onPressed: () => onSuggestionSelected(suggestion),
                              visualDensity: VisualDensity.compact,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  _FeedbackContent _resolveContent(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return switch (status) {
      UsernameAvailabilityStatus.waiting => _FeedbackContent(
        icon: Icons.info_outline_rounded,
        color: colorScheme.onSurfaceVariant,
        message: context.l10n.tr(AppLocaleKeys.authUsernameRestrictionHint),
      ),
      UsernameAvailabilityStatus.checking => _FeedbackContent(
        icon: Icons.info_outline_rounded,
        color: colorScheme.onSurfaceVariant,
        message: context.l10n.tr(AppLocaleKeys.authUsernameChecking),
      ),
      UsernameAvailabilityStatus.available => _FeedbackContent(
        icon: Icons.check_circle_rounded,
        color: colorScheme.primary,
        message: context.l10n.tr(AppLocaleKeys.authUsernameReady),
      ),
      UsernameAvailabilityStatus.unavailable => _FeedbackContent(
        icon: Icons.cancel_rounded,
        color: colorScheme.error,
        message: context.l10n.tr(AppLocaleKeys.authUsernameUnavailable),
      ),
      UsernameAvailabilityStatus.failed => _FeedbackContent(
        icon: Icons.info_outline_rounded,
        color: colorScheme.onSurfaceVariant,
        message: context.l10n.tr(AppLocaleKeys.authUsernameAvailabilityFailed),
      ),
      UsernameAvailabilityStatus.idle => _FeedbackContent(
        icon: Icons.info_outline_rounded,
        color: colorScheme.onSurfaceVariant,
        message: context.l10n.tr(AppLocaleKeys.authUsernameRestrictionHint),
      ),
    };
  }
}

final class _FeedbackContent {
  const _FeedbackContent({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;
}
