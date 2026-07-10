import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';
import 'heimdall_card.dart';
import 'side_pill.dart';

class DebateParticipantTile extends StatelessWidget {
  const DebateParticipantTile({required this.participant, super.key});

  final Debater participant;

  @override
  Widget build(BuildContext context) {
    return HeimdallCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(participant.avatarColor),
            child: Text(participant.name.characters.first),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              participant.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SidePill(side: participant.side, selected: true),
        ],
      ),
    );
  }
}
