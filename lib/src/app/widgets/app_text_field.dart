import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';

final class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.labelText,
    this.isRequired = false,
    this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autocorrect,
    this.enableSuggestions,
    this.enableIMEPersonalizedLearning,
    this.autofillHints,
    this.onFieldSubmitted,
    this.errorMaxLines = 3,
  });

  final String labelText;
  final bool isRequired;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool? autocorrect;
  final bool? enableSuggestions;
  final bool? enableIMEPersonalizedLearning;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final int? errorMaxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  static const ValidationRuleSet _requiredValidationRuleSet = ValidationRuleSet(
    <ValidationRule>[RequiredValidationRule()],
  );

  static const BoxConstraints _iconConstraints = BoxConstraints(
    minWidth: 48,
    minHeight: 48,
  );

  bool _obscureText = false;
  bool _isFocused = false;
  bool _isPasswordTogglePressed = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool effectiveAutocorrect = widget.autocorrect ?? !widget.obscureText;
    final bool effectiveEnableSuggestions =
        widget.enableSuggestions ?? !widget.obscureText;
    final bool effectiveEnableIMEPersonalizedLearning =
        widget.enableIMEPersonalizedLearning ?? !widget.obscureText;
    final Widget obscureToggleIcon = Semantics(
      button: true,
      label: context.l10n.tr(
        _obscureText
            ? AppLocaleKeys.commonShowPassword
            : AppLocaleKeys.commonHidePassword,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (_isPasswordTogglePressed) {
            return;
          }

          setState(() {
            _isPasswordTogglePressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _isPasswordTogglePressed = false;
            _obscureText = !_obscureText;
          });
        },
        onTapCancel: () {
          if (!_isPasswordTogglePressed) {
            return;
          }

          setState(() {
            _isPasswordTogglePressed = false;
          });
        },
        child: AnimatedScale(
          scale: _isPasswordTogglePressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
    );
    final Widget? effectiveSuffixIcon = widget.obscureText
        ? (widget.suffixIcon == null
              ? obscureToggleIcon
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[widget.suffixIcon!, obscureToggleIcon],
                ))
        : widget.suffixIcon;

    return Focus(
      onFocusChange: _handleFocusChange,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        obscureText: _obscureText,
        autocorrect: effectiveAutocorrect,
        enableSuggestions: effectiveEnableSuggestions,
        enableIMEPersonalizedLearning: effectiveEnableIMEPersonalizedLearning,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        onFieldSubmitted: widget.onFieldSubmitted,
        validator: (String? value) {
          if (widget.isRequired) {
            final String? requiredMessage = _requiredValidationRuleSet
                .asValidator(
                  (ValidationFailure failure) => context.l10n.trArgs(
                    failure.messageKey,
                    args: failure.arguments,
                  ),
                )
                .call(value);

            if (requiredMessage != null && requiredMessage.isNotEmpty) {
              return requiredMessage;
            }
          }

          final String? Function(String?)? customValidator = widget.validator;
          if (customValidator == null) {
            return null;
          }

          return customValidator(value);
        },
        cursorColor: colorScheme.primary,
        textAlignVertical: TextAlignVertical.center,
        style: _inputTextStyle(theme),
        decoration: InputDecoration(
          label: _buildLabel(context),
          hintText: widget.hintText,
          errorText: widget.errorText,
          errorMaxLines: widget.errorMaxLines,
          prefixIcon: widget.prefixIcon,
          suffixIcon: effectiveSuffixIcon,
          prefixIconConstraints: _iconConstraints,
          suffixIconConstraints: _iconConstraints,
          errorStyle: TextStyle(color: colorScheme.error),
        ),
      ),
    );
  }

  void _handleFocusChange(bool hasFocus) {
    if (_isFocused == hasFocus) {
      return;
    }

    setState(() {
      _isFocused = hasFocus;
    });
  }

  TextStyle _inputTextStyle(ThemeData theme) {
    final TextStyle baseStyle = theme.textTheme.bodyLarge ?? const TextStyle();

    return baseStyle.copyWith(color: theme.colorScheme.onSurface);
  }

  Widget _buildLabel(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle normalLabelStyle =
        theme.inputDecorationTheme.labelStyle ??
        theme.textTheme.bodyMedium ??
        const TextStyle();
    final TextStyle floatingLabelStyle =
        theme.inputDecorationTheme.floatingLabelStyle ??
        theme.textTheme.bodySmall ??
        normalLabelStyle;
    final TextStyle effectiveLabelStyle = _isFocused
        ? floatingLabelStyle
        : normalLabelStyle;

    if (_isFocused || !widget.isRequired) {
      return Text(widget.labelText, style: effectiveLabelStyle);
    }

    final double baseFontSize =
        effectiveLabelStyle.fontSize ?? normalLabelStyle.fontSize ?? 14;

    return Text.rich(
      TextSpan(
        text: widget.labelText,
        style: effectiveLabelStyle,
        children: <InlineSpan>[
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Text(
              ' *',
              style: effectiveLabelStyle.copyWith(
                fontSize: baseFontSize * 0.85,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
