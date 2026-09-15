import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// App's text field: M3 Expressive wrapper with a floating label, optional
/// leading/trailing widgets, supporting and error text.
class AppTextForm extends StatelessWidget {
  const AppTextForm({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.supportingText,
    this.errorText,
    this.leading,
    this.trailing,
    this.variant = M3ETextFieldVariant.filled,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTapOutside,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  final String? label;
  final String? supportingText;
  final String? errorText;

  final Widget? leading;
  final Widget? trailing;

  final M3ETextFieldVariant variant;

  final bool obscureText;
  final bool enabled;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TapRegionCallback? onTapOutside;

  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return M3ETextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      supportingText: supportingText,
      errorText: errorText,
      leading: leading,
      trailing: trailing,
      variant: variant,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTapOutside: onTapOutside,
      maxLines: maxLines,
    );
  }
}
