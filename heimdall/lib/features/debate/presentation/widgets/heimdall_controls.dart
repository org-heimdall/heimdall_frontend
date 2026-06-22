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

    return SizedBox(
      width: double.infinity,
      height: 57,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: enabled ? null : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              gradient: enabled
                  ? const LinearGradient(
                      colors: [Color(0xFF526BFF), AppColors.primary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? AppColors.textSecondary
                      : AppColors.textMuted,
                  fontSize: 18,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HeimdallBottomActionBar extends StatelessWidget {
  const HeimdallBottomActionBar({
    required this.label,
    required this.onPressed,
    this.active = true,
    this.includeSafeArea = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool active;
  final bool includeSafeArea;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = includeSafeArea
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    final bottomInset = includeSafeArea ? 16.0 + bottomPadding : 32.0;

    return SizedBox(
      width: double.infinity,
      height: 73 + bottomInset,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.surface)),
        ),
        child: HeimdallPrimaryButton(
          label: label,
          onPressed: onPressed,
          active: active,
        ),
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
