import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextForm extends StatelessWidget {
  const AppTextForm({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.supportingText,
    this.errorText,
    this.leading,
    this.trailing,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTapOutside,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  final String? label;
  final String? hintText;
  final String? supportingText;
  final String? errorText;

  final Widget? leading;
  final Widget? trailing;

  final bool obscureText;
  final bool enabled;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TapRegionCallback? onTapOutside;

  final FormFieldValidator<String>? validator;

  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        onTapOutside: onTapOutside,
        validator: validator,
        maxLines: obscureText ? 1 : maxLines,
        style: theme.textTheme.bodyLarge,
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: supportingText,
          errorText: errorText,
          prefixIcon: leading,
          suffixIcon: trailing,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.error),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),

          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          floatingLabelStyle: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIconColor: colorScheme.onSurfaceVariant,
          suffixIconColor: colorScheme.onSurfaceVariant,
          errorStyle: TextStyle(color: colorScheme.error, fontSize: 12),
        ),
      ),
    );
  }
}
