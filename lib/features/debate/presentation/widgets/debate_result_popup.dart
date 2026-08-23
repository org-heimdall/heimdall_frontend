import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
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
                child: ref
                    .watch(debateResultProvider(debateId))
                    .when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      error: (error, stackTrace) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '토론 결과를 불러오지 못했습니다.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => ref.invalidate(
                                debateResultProvider(debateId),
                              ),
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                      data: (result) => _DebateResultPopupBody(result: result),
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
  const _DebateResultPopupBody({required this.result});

  final DebateResult result;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '최종 승자',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                result.winner == DebateWinner.draw
                    ? result.winner.label
                    : '${result.winner.label} 측',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final score in result.scores)
                    Expanded(
                      child: Text(
                        '${score.side.label} ${score.score}점',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _PopupSectionTitle('판정 근거'),
        Text(
          result.reason,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
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
            _PopupFactCheckCard(result: factCheck),
        const SizedBox(height: 10),
        const _PopupSectionTitle('개선 피드백'),
        Text(
          result.feedback,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }
}

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
  const _PopupFactCheckCard({required this.result});

  final FactCheckResult result;

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
          Text(
            result.status.label,
            style: const TextStyle(
              color: AppColors.primarySoft,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
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
