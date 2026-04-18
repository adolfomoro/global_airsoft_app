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

  static const EdgeInsets _zeroPadding = EdgeInsets.zero;
  static const VisualDensity _compactDensity = VisualDensity.compact;

  bool _obscureText = false;

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
    final Widget obscureToggleIcon = IconButton(
      tooltip: context.l10n.tr(
        _obscureText
            ? AppLocaleKeys.commonShowPassword
            : AppLocaleKeys.commonHidePassword,
      ),
      padding: _zeroPadding,
      visualDensity: _compactDensity,
      constraints: _iconConstraints,
      icon: Icon(
        _obscureText
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
      ),
      onPressed: () {
        setState(() {
          _obscureText = !_obscureText;
        });
      },
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
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      obscureText: _obscureText,
      autocorrect: effectiveAutocorrect,
      enableSuggestions: effectiveEnableSuggestions,
      enableIMEPersonalizedLearning: effectiveEnableIMEPersonalizedLearning,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
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
      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        label: _buildLabel(context),
        hintText: widget.hintText,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: effectiveSuffixIcon,
        prefixIconConstraints: _iconConstraints,
        suffixIconConstraints: _iconConstraints,
        errorStyle: TextStyle(color: colorScheme.error),
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? labelStyle =
        theme.inputDecorationTheme.labelStyle ?? theme.textTheme.bodyMedium;
    final Color hintColor =
        theme.inputDecorationTheme.hintStyle?.color ??
        labelStyle?.color ??
        theme.colorScheme.onSurfaceVariant;

    if (!widget.isRequired) {
      return Text(widget.labelText, style: labelStyle);
    }

    return Text.rich(
      TextSpan(
        text: widget.labelText,
        style: labelStyle,
        children: <InlineSpan>[
          TextSpan(
            text: ' *',
            style: labelStyle?.copyWith(
              color: hintColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
