import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';
import 'debate_elapsed_time.dart';
import 'community_status_label.dart';

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
                  _ParticipantAvatars(community: community),
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
            DebateElapsedTime(minutes: community.debateDurationMinutes),
          ],
        ),
      ),
    );
  }
}

class _ParticipantAvatars extends StatelessWidget {
  const _ParticipantAvatars({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final participants = community.participantPreviews.isEmpty
        ? [
            CommunityParticipantPreview(
              id: community.host.id ?? 'host',
              displayName: community.host.name,
              profileImageUrl: community.host.profileImageUrl,
            ),
          ]
        : community.participantPreviews;
    final visible = participants.take(2).toList();

    final baseWidth = 28.0 + (visible.length - 1).clamp(0, 1) * 16.0;
    return SizedBox(
      height: 28,
      width: baseWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              right: i * 16.0,
              child: _ParticipantAvatar(participant: visible[i]),
            ),
        ],
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({required this.participant});

  final CommunityParticipantPreview participant;

  @override
  Widget build(BuildContext context) {
    final imageUrl = participant.profileImageUrl?.trim();
    final fallback = ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Text(
          participant.displayName.trim().isEmpty
              ? '?'
              : participant.displayName.characters.first,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    return SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: imageUrl == null || imageUrl.isEmpty
                ? fallback
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                  ),
          ),
        ),
      ),
    );
  }
}
