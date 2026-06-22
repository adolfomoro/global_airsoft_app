import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_text_field.dart';

final class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    this.focusNode,
    this.labelText = 'Password',
    this.hintText,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.onEditingComplete,
    this.errorText,
    this.validator,
    this.isRequired = false,
    this.textInputAction = TextInputAction.done,
    this.enabled,
    this.readOnly = false,
    this.autofocus = false,
    this.autovalidateMode,
    this.inputFormatters,
    this.autofillHints = const <String>[AutofillHints.password],
    this.prefixIcon,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;
  final String? errorText;
  final String? Function(String?)? validator;
  final bool isRequired;
  final TextInputAction textInputAction;
  final bool? enabled;
  final bool readOnly;
  final bool autofocus;
  final AutovalidateMode? autovalidateMode;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

final class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      labelText: widget.labelText,
      hintText: widget.hintText,
      isRequired: widget.isRequired,
      controller: widget.controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      onTap: widget.onTap,
      onEditingComplete: widget.onEditingComplete,
      errorText: widget.errorText,
      validator: widget.validator,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      autovalidateMode: widget.autovalidateMode,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      prefixIcon: widget.prefixIcon,
      suffixIcon: _PasswordFieldSuffix(
        obscureText: _obscureText,
        onToggle: _toggleObscureText,
        trailing: widget.suffixIcon,
      ),
    );
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
}

final class _PasswordFieldSuffix extends StatelessWidget {
  const _PasswordFieldSuffix({
    required this.obscureText,
    required this.onToggle,
    this.trailing,
  });

  final bool obscureText;
  final VoidCallback onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...[trailing].nonNulls,
        _PasswordVisibilityToggle(
          obscureText: obscureText,
          onToggle: onToggle,
        ),
      ],
    );
  }
}

final class _PasswordVisibilityToggle extends StatefulWidget {
  const _PasswordVisibilityToggle({
    required this.obscureText,
    required this.onToggle,
  });

  final bool obscureText;
  final VoidCallback onToggle;

  @override
  State<_PasswordVisibilityToggle> createState() =>
      _PasswordVisibilityToggleState();
}

final class _PasswordVisibilityToggleState
    extends State<_PasswordVisibilityToggle> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final String passwordToggleLabel = context.l10n.tr(
      widget.obscureText
          ? AppLocaleKeys.commonShowPassword
          : AppLocaleKeys.commonHidePassword,
    );

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerCancel: (_) => _setPressed(false),
      onPointerUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: IconButton(
          tooltip: passwordToggleLabel,
          onPressed: widget.onToggle,
          icon: Icon(
            widget.obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }
}