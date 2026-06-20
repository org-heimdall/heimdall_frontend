import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';

class ParticipantStack extends StatelessWidget {
  const ParticipantStack({required this.activeDebaters, super.key});

  final List<Debater> activeDebaters;

  @override
  Widget build(BuildContext context) {
    if (activeDebaters.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: activeDebaters.length == 1 ? 28 : 44,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < activeDebaters.length.clamp(0, 2); i++)
            Positioned(
              left: i * 16,
              child: _Avatar(participant: activeDebaters[i]),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.participant});

  final Debater participant;

  @override
  Widget build(BuildContext context) {
    final image = participant.side == DebateSide.pro
        ? AppAssets.avatarBlue
        : AppAssets.avatarRed;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(participant.avatarColor),
        border: Border.all(color: AppColors.card, width: 1.5),
        gradient: LinearGradient(
          colors: [
            Color(participant.avatarColor),
            Color(participant.avatarColor).withValues(alpha: 0.65),
            AppColors.background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            participant.name.characters.first,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
