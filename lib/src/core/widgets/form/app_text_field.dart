import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.enabled,
    this.readOnly = false,
    this.autofocus = false,
    this.onTap,
    this.onEditingComplete,
    this.autovalidateMode,
    this.inputFormatters,
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
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final bool? enabled;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;
  final AutovalidateMode? autovalidateMode;
  final List<TextInputFormatter>? inputFormatters;

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
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
    _effectiveFocusNode.addListener(_handleFocusNodeChange);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }

    if (oldWidget.focusNode == widget.focusNode) {
      return;
    }

    oldWidget.focusNode?.removeListener(_handleFocusNodeChange);
    _internalFocusNode?.removeListener(_handleFocusNodeChange);
    if (oldWidget.focusNode == null) {
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    }

    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
    _effectiveFocusNode.addListener(_handleFocusNodeChange);
    _isFocused = _effectiveFocusNode.hasFocus;
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusNodeChange);
    _internalFocusNode?.removeListener(_handleFocusNodeChange);
    _internalFocusNode?.dispose();
    super.dispose();
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
    final String passwordToggleLabel = context.l10n.tr(
      _obscureText
          ? AppLocaleKeys.commonShowPassword
          : AppLocaleKeys.commonHidePassword,
    );
    final Widget obscureToggleIcon = Listener(
      onPointerDown: (_) => _handlePasswordTogglePressed(),
      onPointerCancel: (_) => _resetPasswordTogglePressed(),
      onPointerUp: (_) => _resetPasswordTogglePressed(),
      child: AnimatedScale(
        scale: _isPasswordTogglePressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: IconButton(
          tooltip: passwordToggleLabel,
          onPressed: _toggleObscureText,
          icon: Icon(
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

    return TextFormField(
      controller: widget.controller,
      focusNode: _effectiveFocusNode,
      onChanged: widget.onChanged,
      obscureText: _obscureText,
      autocorrect: effectiveAutocorrect,
      enableSuggestions: effectiveEnableSuggestions,
      enableIMEPersonalizedLearning: effectiveEnableIMEPersonalizedLearning,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onFieldSubmitted,
      onTap: widget.onTap,
      onEditingComplete: widget.onEditingComplete,
      minLines: widget.minLines,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      autovalidateMode: widget.autovalidateMode,
      inputFormatters: widget.inputFormatters,
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
    );
  }

  void _handleFocusNodeChange() {
    final bool hasFocus = _effectiveFocusNode.hasFocus;
    if (_isFocused == hasFocus || !mounted) {
      return;
    }

    setState(() {
      _isFocused = hasFocus;
    });
  }

  void _toggleObscureText() {
    setState(() {
      _isPasswordTogglePressed = false;
      _obscureText = !_obscureText;
    });
  }

  void _handlePasswordTogglePressed() {
    if (_isPasswordTogglePressed) {
      return;
    }

    setState(() {
      _isPasswordTogglePressed = true;
    });
  }

  void _resetPasswordTogglePressed() {
    if (!_isPasswordTogglePressed || !mounted) {
      return;
    }

    setState(() {
      _isPasswordTogglePressed = false;
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
