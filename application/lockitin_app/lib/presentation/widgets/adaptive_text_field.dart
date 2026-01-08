import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Platform-adaptive text field that uses CupertinoTextField on iOS and TextField on Android
///
/// Automatically adapts to platform conventions:
/// - iOS: CupertinoTextField with iOS-style decoration
/// - Android: TextField with Material decoration
///
/// Usage:
/// ```dart
/// AdaptiveTextField(
///   controller: controller,
///   placeholder: 'Enter your name',
///   onChanged: (value) => print(value),
/// )
/// ```
class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? label;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final Widget? prefix;
  final Widget? suffix;
  final EdgeInsetsGeometry? padding;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextStyle? style;

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.label,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onEditingComplete,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.prefix,
    this.suffix,
    this.padding,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    // Wrap in Column if we have a label or helper text (Material-style layout on iOS too)
    if (label != null || helperText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
          ],
          platform == TargetPlatform.iOS
              ? _buildCupertinoTextField(context)
              : _buildMaterialTextField(context),
          if (helperText != null && errorText == null) ...[
            const SizedBox(height: 4),
            Text(
              helperText!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      );
    }

    return platform == TargetPlatform.iOS
        ? _buildCupertinoTextField(context)
        : _buildMaterialTextField(context);
  }

  Widget _buildCupertinoTextField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      onEditingComplete: onEditingComplete,
      focusNode: focusNode,
      autofocus: autofocus,
      readOnly: readOnly,
      enabled: enabled,
      prefix: prefix != null
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: prefix,
            )
          : null,
      suffix: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: 8),
              child: suffix,
            )
          : null,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: style,
      decoration: BoxDecoration(
        color: enabled
            ? CupertinoColors.tertiarySystemBackground
            : CupertinoColors.quaternarySystemFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: errorText != null
              ? colorScheme.error
              : CupertinoColors.separator,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildMaterialTextField(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      onEditingComplete: onEditingComplete,
      focusNode: focusNode,
      autofocus: autofocus,
      readOnly: readOnly,
      enabled: enabled,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: style,
      decoration: InputDecoration(
        hintText: placeholder,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefix,
        suffixIcon: suffix,
        contentPadding: padding,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// Platform-adaptive form text field (with validation)
///
/// Same as AdaptiveTextField but wraps in FormField for form validation
class AdaptiveTextFormField extends FormField<String> {
  final TextEditingController? controller;

  AdaptiveTextFormField({
    super.key,
    this.controller,
    String? placeholder,
    String? label,
    String? helperText,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool autocorrect = true,
    bool enableSuggestions = true,
    int? maxLines = 1,
    int? minLines,
    int? maxLength,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onTap,
    VoidCallback? onEditingComplete,
    FocusNode? focusNode,
    bool autofocus = false,
    bool readOnly = false,
    bool enabled = true,
    Widget? prefix,
    Widget? suffix,
    EdgeInsetsGeometry? padding,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextStyle? style,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    String? initialValue,
    AutovalidateMode? autovalidateMode,
  })  : assert(
          controller == null || initialValue == null,
          'Cannot provide both controller and initialValue',
        ),
        super(
          validator: validator,
          onSaved: onSaved,
          initialValue: controller != null ? controller.text : initialValue,
          autovalidateMode: autovalidateMode,
          builder: (FormFieldState<String> field) {
            final effectiveController = controller ?? TextEditingController();
            if (controller == null) {
              effectiveController.text = field.value ?? '';
            }

            return AdaptiveTextField(
              controller: effectiveController,
              placeholder: placeholder,
              label: label,
              helperText: helperText,
              errorText: field.errorText,
              keyboardType: keyboardType,
              obscureText: obscureText,
              autocorrect: autocorrect,
              enableSuggestions: enableSuggestions,
              maxLines: maxLines,
              minLines: minLines,
              maxLength: maxLength,
              textInputAction: textInputAction,
              onChanged: (value) {
                field.didChange(value);
                onChanged?.call(value);
              },
              onSubmitted: onSubmitted,
              onTap: onTap,
              onEditingComplete: onEditingComplete,
              focusNode: focusNode,
              autofocus: autofocus,
              readOnly: readOnly,
              enabled: enabled,
              prefix: prefix,
              suffix: suffix,
              padding: padding,
              inputFormatters: inputFormatters,
              textCapitalization: textCapitalization,
              style: style,
            );
          },
        );
}
