import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class DebateElapsedTime extends StatelessWidget {
  const DebateElapsedTime({required this.minutes, super.key});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: Center(
            child: SvgPicture.asset(
              AppAssets.timerIcon,
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(
                AppColors.textMuted,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 1),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '$minutes분',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}
