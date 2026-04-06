import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'app_text_input.dart';

class AppPasswordInput extends StatefulWidget {
  const AppPasswordInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;

  @override
  State<AppPasswordInput> createState() => _AppPasswordInputState();
}

class _AppPasswordInputState extends State<AppPasswordInput> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return AppTextInput(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      obscureText: !_isPasswordVisible,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      prefixIcon: widget.prefixIcon,
      suffixIcon: _PasswordVisibilityToggle(
        isVisible: _isPasswordVisible,
        onToggle: _togglePasswordVisibility,
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }
}

class _PasswordVisibilityToggle extends StatelessWidget {
  const _PasswordVisibilityToggle({
    required this.isVisible,
    required this.onToggle,
  });

  final bool isVisible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: FaIcon(
        isVisible ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
        size: 18,
      ),
      onPressed: onToggle,
      tooltip: isVisible ? 'Esconder senha' : 'Mostrar senha',
      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
      padding: const EdgeInsets.only(right: 16, left: 4),
    );
  }
}
