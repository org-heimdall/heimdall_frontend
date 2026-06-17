import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debate_room.dart';

class SidePill extends StatelessWidget {
  const SidePill({
    required this.side,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final DebateSide side;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sideColor = side == DebateSide.pro ? AppColors.pro : AppColors.con;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? sideColor.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? sideColor : Colors.transparent),
        ),
        child: Text(
          side.label,
          style: TextStyle(
            color: selected ? sideColor : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
