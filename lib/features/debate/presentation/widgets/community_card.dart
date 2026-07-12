import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';
import 'debate_elapsed_time.dart';
import 'community_status_label.dart';
import 'participant_stack.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    required this.community,
    required this.onTap,
    super.key,
  });

  final Community community;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          gradient: const RadialGradient(
            center: Alignment(0.0, 0.1),
            radius: 1.7,
            colors: [Color(0xFF2A3041), Color(0xFF262C33)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommunityStatusLabel.fromStatus(status: community.status),
                  if (community.status == CommunityStatus.live)
                    ParticipantStack(activeDebaters: community.activeDebaters),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    community.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${community.observerCount}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 18,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            DebateElapsedTime(minutes: community.elapsedMinutes),
          ],
        ),
      ),
    );
  }
}
