import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:la_pocha/core/theme/app_theme.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.autocorrect = true,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool autocorrect;
  final void Function(String)? onFieldSubmitted;
  final IconData? prefixIcon;
  final int? maxLength;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText && !widget.obscureText) {
      _obscure = false;
    }
  }

  OutlineInputBorder _border({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: color ?? AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
        width: width,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText && _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autocorrect: widget.autocorrect,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: theme.textTheme.bodyLarge,
      maxLength: widget.maxLength,
      inputFormatters: widget.maxLength != null
          ? [LengthLimitingTextInputFormatter(widget.maxLength)]
          : null,
      decoration: InputDecoration(
        labelText: widget.label,
        counterText: widget.maxLength != null ? '' : null,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(color: AppTheme.primary, width: 2),
        errorBorder: _border(color: theme.colorScheme.error),
        focusedErrorBorder: _border(color: theme.colorScheme.error, width: 2),
      ),
    );
  }
}
