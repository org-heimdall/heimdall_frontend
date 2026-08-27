import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/entities/debate_side.dart';
import '../../domain/entities/debate_chat_realtime.dart';
import '../../domain/entities/debate_result.dart';
import '../providers/debate_chat_providers.dart';

class DebateResultPopup extends ConsumerWidget {
  const DebateResultPopup({
    required this.debateId,
    required this.onClose,
    super.key,
  });

  final String debateId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(debateResultProvider(debateId));
    final detailAsync = ref.watch(debateDetailProvider(debateId));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 402,
          maxHeight: MediaQuery.sizeOf(context).height * 0.84,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '토론 결과',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textMuted,
                      tooltip: '닫기',
                    ),
                  ],
                ),
              ),
              Flexible(
                child: resultAsync.when(
                  loading: () => const _PopupLoading(),
                  error: (error, stackTrace) => _PopupError(
                    onRetry: () =>
                        ref.invalidate(debateResultProvider(debateId)),
                  ),
                  data: (result) => detailAsync.when(
                    loading: () => const _PopupLoading(),
                    error: (error, stackTrace) => _PopupError(
                      onRetry: () =>
                          ref.invalidate(debateDetailProvider(debateId)),
                    ),
                    data: (detail) => _DebateResultPopupBody(
                      result: result,
                      debateDetail: detail,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebateResultPopupBody extends StatelessWidget {
  const _DebateResultPopupBody({
    required this.result,
    required this.debateDetail,
  });

  final DebateResult result;
  final DebateDetail debateDetail;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _ObserverResultMatchup(
              result: result,
              sideASpeaker: debateDetail.sideASpeaker,
              sideBSpeaker: debateDetail.sideBSpeaker,
            ),
            const SizedBox(height: 18),
            const _PopupSectionTitle('판정 근거'),
            Text(
              result.reason,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            const _PopupSectionTitle('Fact Check'),
            if (result.factChecks.isEmpty)
              const Text(
                '검증 대상이 된 사실 주장이 없습니다.',
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              for (final factCheck in result.factChecks)
                _PopupFactCheckCard(
                  result: factCheck,
                  speaker: _speakerFor(factCheck),
                  isWinner: _isWinningSpeaker(factCheck),
                  isDefeated: _isDefeatedSpeaker(factCheck),
                ),
            const SizedBox(height: 10),
            const _PopupSectionTitle('개선 피드백'),
            _PopupFeedbackCard(
              speaker: debateDetail.sideASpeaker,
              feedback: _feedbackFor(DebateSide.pro),
              isWinner: result.winner == DebateWinner.pro,
              isDefeated: result.winner == DebateWinner.con,
            ),
            _PopupFeedbackCard(
              speaker: debateDetail.sideBSpeaker,
              feedback: _feedbackFor(DebateSide.con),
              isWinner: result.winner == DebateWinner.con,
              isDefeated: result.winner == DebateWinner.pro,
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: const IgnorePointer(
            child: DecoratedBox(
              key: ValueKey('debate-result-bottom-fade'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x0022282D), AppColors.surface],
                ),
              ),
              child: SizedBox(height: 40),
            ),
          ),
        ),
      ],
    );
  }

  String _feedbackFor(DebateSide side) {
    final feedback = result.scores
        .firstWhere(
          (score) => score.side == side,
          orElse: () => DebateScore(side: side, score: 0, summary: ''),
        )
        .summary
        .trim();
    return feedback.isEmpty ? '제공된 개선 피드백이 없습니다.' : feedback;
  }

  DebateSpeaker? _speakerFor(FactCheckResult factCheck) {
    if (factCheck.speakerId == debateDetail.sideASpeaker.id ||
        factCheck.speakerSide == 'SIDE_A') {
      return debateDetail.sideASpeaker;
    }
    if (factCheck.speakerId == debateDetail.sideBSpeaker.id ||
        factCheck.speakerSide == 'SIDE_B') {
      return debateDetail.sideBSpeaker;
    }
    return null;
  }

  bool _isWinningSpeaker(FactCheckResult factCheck) {
    return switch (result.winner) {
      DebateWinner.pro =>
        factCheck.speakerId == debateDetail.sideASpeaker.id ||
            factCheck.speakerSide == 'SIDE_A',
      DebateWinner.con =>
        factCheck.speakerId == debateDetail.sideBSpeaker.id ||
            factCheck.speakerSide == 'SIDE_B',
      DebateWinner.draw => false,
    };
  }

  bool _isDefeatedSpeaker(FactCheckResult factCheck) {
    return _speakerFor(factCheck) != null &&
        result.winner != DebateWinner.draw &&
        !_isWinningSpeaker(factCheck);
  }
}

class _ObserverResultMatchup extends StatelessWidget {
  const _ObserverResultMatchup({
    required this.result,
    required this.sideASpeaker,
    required this.sideBSpeaker,
  });

  final DebateResult result;
  final DebateSpeaker sideASpeaker;
  final DebateSpeaker sideBSpeaker;

  @override
  Widget build(BuildContext context) {
    final sideA = _ObserverParticipant(
      speaker: sideASpeaker,
      score: _scoreFor(DebateSide.pro),
      isWinner: result.winner == DebateWinner.pro,
    );
    final sideB = _ObserverParticipant(
      speaker: sideBSpeaker,
      score: _scoreFor(DebateSide.con),
      isWinner: result.winner == DebateWinner.con,
    );
    final isDraw = result.winner == DebateWinner.draw;
    final left = result.winner == DebateWinner.con ? sideB : sideA;
    final right = result.winner == DebateWinner.con ? sideA : sideB;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            isDraw ? '무승부' : '최종 판정',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ObserverParticipantView(
                  key: const ValueKey('observer-result-left-participant'),
                  participant: left,
                  isDraw: isDraw,
                ),
              ),
              SizedBox(
                width: 38,
                height: 112,
                child: Center(
                  child: Text(
                    isDraw ? 'DRAW' : 'VS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: isDraw ? 11 : 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _ObserverParticipantView(
                  key: const ValueKey('observer-result-right-participant'),
                  participant: right,
                  isDraw: isDraw,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DebateScore _scoreFor(DebateSide side) => result.scores.firstWhere(
    (score) => score.side == side,
    orElse: () => DebateScore(side: side, score: 0, summary: ''),
  );
}

class _ObserverParticipant {
  const _ObserverParticipant({
    required this.speaker,
    required this.score,
    required this.isWinner,
  });

  final DebateSpeaker speaker;
  final DebateScore score;
  final bool isWinner;
}

class _ObserverParticipantView extends StatelessWidget {
  const _ObserverParticipantView({
    required this.participant,
    required this.isDraw,
    super.key,
  });

  final _ObserverParticipant participant;
  final bool isDraw;

  @override
  Widget build(BuildContext context) {
    final isWinner = participant.isWinner && !isDraw;
    final isDefeated = !participant.isWinner && !isDraw;
    const avatarSize = 76.0;
    final claim = participant.speaker.claim.trim().isEmpty
        ? '등록된 주장이 없습니다.'
        : participant.speaker.claim.trim();

    return Column(
      children: [
        SizedBox(
          height: 112,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              _ObserverResultAvatar(
                speaker: participant.speaker,
                size: avatarSize,
                isWinner: isWinner,
                isDefeated: isDefeated,
              ),
              if (isWinner)
                const Positioned(top: 20, child: _ObserverWinnerBadge()),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          participant.speaker.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${participant.score.score}점',
          style: TextStyle(
            color: isWinner ? const Color(0xFFFFD54F) : AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          claim,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ObserverWinnerBadge extends StatelessWidget {
  const _ObserverWinnerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('observer-result-winner-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xE62B2715),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: const Text(
        'WINNER',
        style: TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _ObserverResultAvatar extends StatelessWidget {
  const _ObserverResultAvatar({
    required this.speaker,
    required this.size,
    required this.isWinner,
    required this.isDefeated,
  });

  final DebateSpeaker speaker;
  final double size;
  final bool isWinner;
  final bool isDefeated;

  @override
  Widget build(BuildContext context) {
    final imageUrl = speaker.profileImageUrl?.trim();
    final image = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl == null || imageUrl.isEmpty
            ? _ObserverAvatarFallback(name: speaker.displayName)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _ObserverAvatarFallback(name: speaker.displayName),
              ),
      ),
    );
    final processedImage = isDefeated
        ? Opacity(
            opacity: 0.6,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
              child: image,
            ),
          )
        : image;

    return Container(
      key: ValueKey('observer-result-avatar-${speaker.id}'),
      width: size + 14,
      height: size + 14,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isWinner ? const Color(0xFFFFD54F) : AppColors.surfaceElevated,
          width: isWinner ? 3 : 1,
        ),
        boxShadow: isWinner
            ? const [BoxShadow(color: Color(0x66FFD54F), blurRadius: 16)]
            : null,
      ),
      child: processedImage,
    );
  }
}

class _ObserverAvatarFallback extends StatelessWidget {
  const _ObserverAvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final normalizedName = name.trim();
    return ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Text(
          normalizedName.isEmpty ? '?' : normalizedName.characters.first,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PopupLoading extends StatelessWidget {
  const _PopupLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _PopupError extends StatelessWidget {
  const _PopupError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '토론 결과를 불러오지 못했습니다.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

const _grayscaleMatrix = <double>[
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

class _PopupSectionTitle extends StatelessWidget {
  const _PopupSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PopupFactCheckCard extends StatelessWidget {
  const _PopupFactCheckCard({
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FactCheckSpeakerAvatar(
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
              Container(
                key: ValueKey('fact-check-status-${result.id}'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  result.status.label,
                  style: const TextStyle(
                    color: AppColors.background,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.claim,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.reason,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
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

class _FactCheckSpeakerAvatar extends StatelessWidget {
  const _FactCheckSpeakerAvatar({
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
              colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
              child: image,
            ),
          )
        : image;

    return Container(
      key: ValueKey('fact-check-speaker-$resultId'),
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

class _PopupFeedbackCard extends StatelessWidget {
  const _PopupFeedbackCard({
    required this.speaker,
    required this.feedback,
    required this.isWinner,
    required this.isDefeated,
  });

  final DebateSpeaker speaker;
  final String feedback;
  final bool isWinner;
  final bool isDefeated;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('feedback-card-${speaker.id}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FactCheckSpeakerAvatar(
                resultId: 'feedback-${speaker.id}',
                speaker: speaker,
                isWinner: isWinner,
                isDefeated: isDefeated,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  speaker.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            feedback,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
