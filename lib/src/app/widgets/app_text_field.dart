import 'package:flutter/material.dart';

final class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.onChanged,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
  });

  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Widget? effectiveSuffixIcon = widget.obscureText
        ? IconButton(
            tooltip: _obscureText ? 'Show password' : 'Hide password',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
          )
        : widget.suffixIcon;

    return TextFormField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      cursorColor: colorScheme.primary,
      textAlignVertical: TextAlignVertical.center,
      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: effectiveSuffixIcon,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        errorStyle: TextStyle(color: colorScheme.error),
      ),
    );
  }
}
