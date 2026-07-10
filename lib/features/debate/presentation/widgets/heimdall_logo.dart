import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class HeimdallLogo extends StatelessWidget {
  const HeimdallLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SvgPicture.asset(
        AppAssets.heimdallLogo,
        width: 169,
        height: 24,
        fit: BoxFit.contain,
      ),
    );
  }
}

class HeimdallBackButton extends StatelessWidget {
  const HeimdallBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      color: AppColors.textPrimary,
      tooltip: '뒤로',
    );
  }
}
