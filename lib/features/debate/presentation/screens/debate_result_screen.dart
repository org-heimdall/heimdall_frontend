import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/presentation/widgets/heimdall_controls.dart';
import '../../domain/entities/debate_result.dart';
import '../../../community/domain/entities/community.dart';
import '../widgets/debate_result_section.dart';
import '../widgets/heimdall_card.dart';
import '../providers/debate_chat_providers.dart';

class DebateResultApiScreen extends ConsumerWidget {
  const DebateResultApiScreen({
    required this.community,
    required this.debateId,
    super.key,
  });

  final Community community;
  final String debateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _returnToCommunityChat(context, community);
      },
      child: ref
          .watch(debateResultProvider(debateId))
          .when(
            data: (result) =>
                DebateResultScreen(community: community, result: result),
            loading: () => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (error, stackTrace) => Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  onPressed: () => _returnToCommunityChat(context, community),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  tooltip: '커뮤니티 채팅방으로 돌아가기',
                ),
              ),
              body: Center(
                child: TextButton(
                  onPressed: () =>
                      ref.invalidate(debateResultProvider(debateId)),
                  child: const Text('판정 결과를 불러오지 못했습니다. 다시 시도'),
                ),
              ),
            ),
          ),
    );
  }
}

class DebateResultScreen extends StatelessWidget {
  const DebateResultScreen({
    required this.community,
    required this.result,
    super.key,
  });

  final Community community;
  final DebateResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => _returnToCommunityChat(context, community),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '커뮤니티 채팅방으로 돌아가기',
        ),
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
                    result.winner == DebateWinner.draw
                        ? result.winner.label
                        : '${result.winner.label} 측',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    community.title,
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
              children: result.factChecks.isEmpty
                  ? const [Text('검증 대상이 된 사실 주장이 없습니다.')]
                  : result.factChecks
                        .map((fact) => _FactCheckCard(result: fact))
                        .toList(),
            ),
            DebateResultSection(
              title: '개선 피드백',
              children: [Text(result.feedback)],
            ),
          ],
        ),
      ),
      bottomNavigationBar: HeimdallBottomActionBar(
        label: '확인',
        onPressed: () => _returnToCommunityChat(context, community),
      ),
    );
  }
}

void _returnToCommunityChat(BuildContext context, Community community) {
  final roleQuery = community.isOwnedByCurrentUser ? '?role=host' : '';
  context.go('/communities/${community.id}/chat$roleQuery');
}

class _FactCheckCard extends StatelessWidget {
  const _FactCheckCard({required this.result});

  final FactCheckResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactCheckStatusBadge(status: result.status),
          const SizedBox(height: 10),
          Text(
            result.claim,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.reason,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (result.sources.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              '출처',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final source in result.sources) ...[
              Text(
                '${source.publisher} · ${source.title}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                source.url,
                style: const TextStyle(
                  color: AppColors.primarySoft,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _FactCheckStatusBadge extends StatelessWidget {
  const _FactCheckStatusBadge({required this.status});

  final FactCheckStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      FactCheckStatus.supported => const Color(0xFF54D18B),
      FactCheckStatus.contradicted => const Color(0xFFFF6B6B),
      FactCheckStatus.partiallySupported => const Color(0xFFFFC857),
      FactCheckStatus.insufficientEvidence ||
      FactCheckStatus.notVerifiable ||
      FactCheckStatus.outdatedOrTimeSensitive ||
      FactCheckStatus.unknown => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
