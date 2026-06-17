import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debate_result.dart';
import '../../domain/entities/debate_room.dart';
import '../widgets/debate_result_section.dart';
import '../widgets/heimdall_card.dart';
import '../widgets/heimdall_logo.dart';

class DebateResultScreen extends StatelessWidget {
  const DebateResultScreen({
    required this.room,
    required this.result,
    super.key,
  });

  final DebateRoom room;
  final DebateResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HeimdallBackButton(),
        title: const Text('AI 판정 결과'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            HeimdallCard(
              padding: const EdgeInsets.all(20),
              color: AppColors.card,
              radius: 20,
              gradient: const RadialGradient(
                center: Alignment(0.6, -0.9),
                radius: 1.6,
                colors: [Color(0x335659FF), AppColors.card],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '최종 승자',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.winner.label} 측',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    room.title,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (final score in result.scores)
                  Expanded(
                    child: HeimdallCard(
                      margin: EdgeInsets.only(
                        right: score == result.scores.first ? 8 : 0,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            score.side.label,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${score.score}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            score.summary,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            DebateResultSection(
              title: '판정 근거',
              children: [Text(result.reason)],
            ),
            DebateResultSection(
              title: '강점',
              children: result.strengths
                  .map((item) => DebateResultBullet(item))
                  .toList(),
            ),
            DebateResultSection(
              title: '약점',
              children: result.weaknesses
                  .map((item) => DebateResultBullet(item))
                  .toList(),
            ),
            DebateResultSection(
              title: 'Fact Check',
              children: result.factChecks
                  .map(
                    (fact) =>
                        DebateResultBullet('${fact.claim} - ${fact.verdict}'),
                  )
                  .toList(),
            ),
            DebateResultSection(
              title: '개선 피드백',
              children: [Text(result.feedback)],
            ),
          ],
        ),
      ),
    );
  }
}
