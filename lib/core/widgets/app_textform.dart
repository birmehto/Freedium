import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// A text field that registers with the surrounding [Form].
///
/// [M3ETextField] paints the field; the [FormField] wrapped around it is what
/// keeps `Form.validate()` working. Validation reads what the field actually
/// shows: the controller's text when there is one — a paste or a clear never
/// fires `onChanged` — and the tracked value otherwise.
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
    this.variant = M3ETextFieldVariant.outlined,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.showClearButton = false,
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

  /// A failure raised by the caller (a rejected URL, for example), shown
  /// alongside whatever the [validator] reports.
  final String? errorText;

  final Widget? leading;
  final Widget? trailing;

  /// Outlined by default: the field sits on the home screen's dark surface,
  /// where the filled variant's tint barely reads.
  final M3ETextFieldVariant variant;

  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final bool showClearButton;

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
    return FormField<String>(
      initialValue: controller?.text ?? '',
      enabled: enabled,
      validator: validator == null
          ? null
          : (value) => validator!(controller?.text ?? value),
      builder: (field) {
        return M3ETextField(
          controller: controller,
          focusNode: focusNode,
          label: label,
          placeholder: hintText,
          supportingText: supportingText,
          errorText: field.errorText ?? errorText,
          leading: leading,
          trailing: trailing,
          variant: variant,
          showClearButton: showClearButton,
          obscureText: obscureText,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          maxLines: obscureText ? 1 : maxLines,
          onChanged: (text) {
            field.didChange(text);
            onChanged?.call(text);
          },
          onSubmitted: onSubmitted,
          onTapOutside: onTapOutside,
        );
      },
    );
  }
}
