import 'package:flutter/material.dart';

class KeepItTextField extends StatelessWidget {
  const KeepItTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.suffixIcon,
    this.helperText,
    this.errorText,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final Widget? suffixIcon;
  final String? helperText;
  final String? errorText;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      autofocus: autofocus,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        helperText: helperText,
        errorText: errorText,
      ),
    );
  }
}
