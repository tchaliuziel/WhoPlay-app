import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.body(14, weight: FontWeight.w600));
}

/// Caixa branca de 52px com contorno, base de todos os campos.
class FieldBox extends StatelessWidget {
  const FieldBox({super.key, required this.child, this.horizontalPadding = 16});

  final Widget child;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [FieldLabel(label), const SizedBox(height: 6), child],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.weight = FontWeight.w500,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String? initialValue;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FontWeight weight;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      child: FieldBox(
        child: TextFormField(
          initialValue: controller == null ? initialValue : null,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          cursorColor: AppColors.primary,
          style: AppText.body(16, weight: weight),
          decoration: const InputDecoration.collapsed(hintText: null),
        ),
      ),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      child: FieldBox(
        horizontalPadding: 12,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            dropdownColor: AppColors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.ink),
            style: AppText.body(16, weight: FontWeight.w600),
            items: [
              for (final e in items.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
