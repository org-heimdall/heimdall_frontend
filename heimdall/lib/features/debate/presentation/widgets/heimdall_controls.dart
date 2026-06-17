import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HeimdallPrimaryButton extends StatelessWidget {
  const HeimdallPrimaryButton({
    required this.label,
    required this.onPressed,
    this.active = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = active && onPressed != null;

    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: enabled ? AppColors.primary : AppColors.surface,
        disabledBackgroundColor: AppColors.surface,
        foregroundColor: enabled ? AppColors.textPrimary : AppColors.textMuted,
        disabledForegroundColor: AppColors.textMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class HeimdallBottomActionBar extends StatelessWidget {
  const HeimdallBottomActionBar({
    required this.label,
    required this.onPressed,
    this.active = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surface)),
      ),
      child: HeimdallPrimaryButton(
        label: label,
        onPressed: onPressed,
        active: active,
      ),
    );
  }
}

class HeimdallTextFormField extends StatelessWidget {
  const HeimdallTextFormField({
    required this.controller,
    required this.label,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }
}
