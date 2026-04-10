import 'package:flutter/material.dart';

final class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.onChanged,
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
    return TextFormField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : widget.suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
