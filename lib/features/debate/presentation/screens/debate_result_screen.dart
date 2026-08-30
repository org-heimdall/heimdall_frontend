import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/entities/debate_side.dart';
import '../../../../shared/presentation/widgets/heimdall_controls.dart';
import '../../domain/entities/debate_result.dart';
import '../../domain/entities/debate_chat_realtime.dart';
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
    final resultValue = ref.watch(debateResultProvider(debateId));
    final detailValue = ref.watch(debateDetailProvider(debateId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _returnToCommunityChat(context, community);
      },
      child: resultValue.when(
        data: (result) => detailValue.when(
          data: (detail) => DebateResultScreen(
            community: community,
            result: result,
            detail: detail,
          ),
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (error, stackTrace) => _ResultLoadError(
            community: community,
            onRetry: () => ref.invalidate(debateDetailProvider(debateId)),
          ),
        ),
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (error, stackTrace) => _ResultLoadError(
          community: community,
          onRetry: () => ref.invalidate(debateResultProvider(debateId)),
        ),
      ),
    );
  }
}

class DebateResultScreen extends StatelessWidget {
  const DebateResultScreen({
    required this.community,
    required this.result,
    required this.detail,
    super.key,
  });

  final Community community;
  final DebateResult result;
  final DebateDetail detail;

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
                  result.winner == DebateWinner.draw
                      ? const Text(
                          '무승부',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1.4,
                          ),
                        )
                      : _WinnerProfile(
                          speaker: result.winner == DebateWinner.pro
                              ? detail.sideASpeaker
                              : detail.sideBSpeaker,
                        ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (
                    var index = 0;
                    index < result.scores.length;
                    index++
                  ) ...[
                    Expanded(
                      child: _DebateScoreCard(
                        score: result.scores[index],
                        speaker: _speakerForScore(result.scores[index], detail),
                      ),
                    ),
                    if (index < result.scores.length - 1)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            DebateResultSection(
              title: '판정 근거',
              children: [Text(result.reason)],
            ),
            DebateResultSection(
              title: 'Fact Check',
              children: result.factChecks.isEmpty
                  ? const [Text('검증 대상이 된 사실 주장이 없습니다.')]
                  : result.factChecks
                        .map(
                          (fact) => _FactCheckCard(
                            result: fact,
                            speaker: _speakerForFactCheck(fact, detail),
                            isWinner: _isWinningFactCheck(fact, result, detail),
                            isDefeated: _isDefeatedFactCheck(
                              fact,
                              result,
                              detail,
                            ),
                          ),
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
      bottomNavigationBar: HeimdallBottomActionBar(
        label: '확인',
        onPressed: () => _returnToCommunityChat(context, community),
      ),
    );
  }
}

class _WinnerProfile extends StatelessWidget {
  const _WinnerProfile({required this.speaker});

  final DebateSpeaker speaker;

  @override
  Widget build(BuildContext context) {
    final displayName = speaker.displayName.trim();
    final imageUrl = speaker.profileImageUrl?.trim();
    final fallback = ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Text(
          displayName.isEmpty ? '?' : displayName.characters.first,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    return Row(
      children: [
        Container(
          key: const ValueKey('debate-result-winner-avatar'),
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD54F), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x55FFD54F), blurRadius: 8),
            ],
          ),
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
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            displayName.isEmpty ? '승자 정보 없음' : displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultLoadError extends StatelessWidget {
  const _ResultLoadError({required this.community, required this.onRetry});

  final Community community;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => _returnToCommunityChat(context, community),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '커뮤니티 채팅방으로 돌아가기',
        ),
      ),
      body: Center(
        child: TextButton(
          onPressed: onRetry,
          child: const Text('판정 결과를 불러오지 못했습니다. 다시 시도'),
        ),
      ),
    );
  }
}

class _DebateScoreCard extends StatelessWidget {
  const _DebateScoreCard({required this.score, required this.speaker});

  final DebateScore score;
  final DebateSpeaker speaker;

  @override
  Widget build(BuildContext context) {
    return HeimdallCard(
      key: ValueKey('debate-score-card-${score.side.name}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            speaker.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    );
  }
}

DebateSpeaker _speakerForScore(DebateScore score, DebateDetail detail) {
  return score.side == DebateSide.pro
      ? detail.sideASpeaker
      : detail.sideBSpeaker;
}

void _returnToCommunityChat(BuildContext context, Community community) {
  final roleQuery = community.isOwnedByCurrentUser ? '?role=host' : '';
  context.go('/communities/${community.id}/chat$roleQuery');
}

class _FactCheckCard extends StatelessWidget {
  const _FactCheckCard({
    required this.result,
    required this.speaker,
    required this.isWinner,
    required this.isDefeated,
  });

  final FactCheckResult result;
  final DebateSpeaker? speaker;
  final bool isWinner;
  final bool isDefeated;

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
          Row(
            children: [
              _ResultFactCheckSpeakerAvatar(
                resultId: result.id,
                speaker: speaker,
                isWinner: isWinner,
                isDefeated: isDefeated,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  speaker?.displayName ?? '발언자 정보 없음',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _FactCheckStatusBadge(status: result.status),
            ],
          ),
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
            const SizedBox(height: 10),
            for (final source in result.sources)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${source.publisher} · ${source.title}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
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
      FactCheckStatus.supported => AppColors.primarySoft,
      FactCheckStatus.partiallySupported => const Color(0xFFB0A064),
      FactCheckStatus.contradicted ||
      FactCheckStatus.notVerifiable ||
      FactCheckStatus.outdated => AppColors.con,
      FactCheckStatus.insufficientEvidence => AppColors.textMuted,
      FactCheckStatus.unknown => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: AppColors.background,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

DebateSpeaker? _speakerForFactCheck(
  FactCheckResult factCheck,
  DebateDetail detail,
) {
  if (factCheck.speakerId == detail.sideASpeaker.id ||
      factCheck.speakerSide == 'SIDE_A') {
    return detail.sideASpeaker;
  }
  if (factCheck.speakerId == detail.sideBSpeaker.id ||
      factCheck.speakerSide == 'SIDE_B') {
    return detail.sideBSpeaker;
  }
  return null;
}

bool _isWinningFactCheck(
  FactCheckResult factCheck,
  DebateResult result,
  DebateDetail detail,
) {
  return switch (result.winner) {
    DebateWinner.pro =>
      factCheck.speakerId == detail.sideASpeaker.id ||
          factCheck.speakerSide == 'SIDE_A',
    DebateWinner.con =>
      factCheck.speakerId == detail.sideBSpeaker.id ||
          factCheck.speakerSide == 'SIDE_B',
    DebateWinner.draw => false,
  };
}

bool _isDefeatedFactCheck(
  FactCheckResult factCheck,
  DebateResult result,
  DebateDetail detail,
) {
  return _speakerForFactCheck(factCheck, detail) != null &&
      result.winner != DebateWinner.draw &&
      !_isWinningFactCheck(factCheck, result, detail);
}

class _ResultFactCheckSpeakerAvatar extends StatelessWidget {
  const _ResultFactCheckSpeakerAvatar({
    required this.resultId,
    required this.speaker,
    required this.isWinner,
    required this.isDefeated,
  });

  final String resultId;
  final DebateSpeaker? speaker;
  final bool isWinner;
  final bool isDefeated;

  @override
  Widget build(BuildContext context) {
    final displayName = speaker?.displayName.trim() ?? '';
    final imageUrl = speaker?.profileImageUrl?.trim();
    final fallback = ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Text(
          displayName.isEmpty ? '?' : displayName.characters.first,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
    final image = ClipOval(
      child: SizedBox(
        width: 28,
        height: 28,
        child: imageUrl == null || imageUrl.isEmpty
            ? fallback
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
    final processedImage = isDefeated
        ? Opacity(
            opacity: 0.6,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(_resultGrayscaleMatrix),
              child: image,
            ),
          )
        : image;

    return Container(
      key: ValueKey('result-fact-check-speaker-$resultId'),
      width: 34,
      height: 34,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isWinner ? const Color(0xFFFFD54F) : AppColors.surfaceElevated,
          width: isWinner ? 2 : 1,
        ),
        boxShadow: isWinner
            ? const [BoxShadow(color: Color(0x55FFD54F), blurRadius: 8)]
            : null,
      ),
      child: processedImage,
    );
  }
}

const _resultGrayscaleMatrix = <double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];
