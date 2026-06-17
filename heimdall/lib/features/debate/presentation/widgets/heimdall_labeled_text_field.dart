import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HeimdallLabeledTextField extends StatelessWidget {
  const HeimdallLabeledTextField({
    required this.label,
    required this.hintText,
    this.controller,
    this.active = false,
    this.maxLines = 1,
    this.validator,
    super.key,
  });

  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool active;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: active ? AppColors.textSecondary : AppColors.textSubtle,
              fontSize: 16,
              height: 1.5,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
