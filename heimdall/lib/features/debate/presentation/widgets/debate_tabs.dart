import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HeimdallTab extends StatelessWidget {
  const HeimdallTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.variant = HeimdallTabVariant.filled,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final HeimdallTabVariant variant;

  @override
  Widget build(BuildContext context) {
    final isOutline = variant == HeimdallTabVariant.outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _backgroundColor(isOutline),
          borderRadius: BorderRadius.circular(12),
          border: isOutline && !selected
              ? Border.all(color: AppColors.border)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _foregroundColor(isOutline),
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(bool isOutline) {
    if (isOutline) {
      return selected ? AppColors.primarySoft : Colors.transparent;
    }
    return selected ? AppColors.primary : AppColors.surface;
  }

  Color _foregroundColor(bool isOutline) {
    if (isOutline) {
      return selected ? AppColors.primary : AppColors.textMuted;
    }
    return selected ? AppColors.textPrimary : AppColors.textMuted;
  }
}

enum HeimdallTabVariant { filled, outline }
