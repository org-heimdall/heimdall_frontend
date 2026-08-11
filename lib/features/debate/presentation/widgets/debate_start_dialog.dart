import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';

class DebateStartDialog extends StatelessWidget {
  const DebateStartDialog({
    required this.community,
    this.showActionButtons = true,
    super.key,
  });

  final Community community;
  final bool showActionButtons;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: Container(
          width: 370,
          height: 620,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  _DialogHeader(showActionButtons: showActionButtons),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoSection(label: '토론 주제', value: community.title),
                          const SizedBox(height: 24),
                          _InfoSection(
                            label: '토론 설명',
                            value: _valueOrFallback(
                              community.topic,
                              '작성된 토론 설명이 없습니다.',
                            ),
                            mutedWhenEmpty: community.topic.trim().isEmpty,
                          ),
                          const SizedBox(height: 24),
                          _RoundSummary(rounds: community.rounds),
                          const SizedBox(height: 24),
                          _InfoSection(
                            label: '나의 주장',
                            value: _valueOrFallback(
                              community.hostClaim,
                              '작성된 주장이 없습니다.',
                            ),
                            mutedWhenEmpty: community.hostClaim.trim().isEmpty,
                          ),
                          const SizedBox(height: 24),
                          _ReasonSection(reasons: community.hostReasons),
                        ],
                      ),
                    ),
                  ),
                  if (showActionButtons)
                    _DialogActions(
                      onCancel: () => Navigator.pop(context, false),
                      onConfirm: () => Navigator.pop(context, true),
                    ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: showActionButtons ? 88 : 0,
                child: const IgnorePointer(
                  child: DecoratedBox(
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
          ),
        ),
      ),
    );
  }

  static String _valueOrFallback(String value, String fallback) {
    return value.trim().isEmpty ? fallback : value;
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.showActionButtons});

  final bool showActionButtons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        children: [
          const Text(
            '토론 정보 확인',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 22,
              height: 1.4,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            showActionButtons
                ? '아래 내용을 확인한 뒤 토론을 시작해주세요.'
                : '커뮤니티에 설정된 토론 정보입니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.label,
    required this.value,
    this.mutedWhenEmpty = false,
  });

  final String label;
  final String value;
  final bool mutedWhenEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: mutedWhenEmpty
                  ? AppColors.textSubtle
                  : AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReasonSection extends StatelessWidget {
  const _ReasonSection({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final visibleReasons = reasons
        .map((reason) => reason.trim())
        .where((reason) => reason.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('근거'),
        const SizedBox(height: 12),
        if (visibleReasons.isEmpty)
          const _EmptyReason()
        else
          for (var index = 0; index < visibleReasons.length; index++) ...[
            _ReasonItem(index: index + 1, reason: visibleReasons[index]),
            if (index != visibleReasons.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _RoundSummary extends StatelessWidget {
  const _RoundSummary({required this.rounds});

  final int rounds;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = rounds * 6 + 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('토론 라운드 개수'),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 329,
            height: 60,
            child: Row(
              children: [
                const Text('라운드', style: _summaryTextStyle),
                const SizedBox(width: 8),
                Container(
                  width: 52,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$rounds',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('개,', style: _summaryTextStyle),
                const Spacer(),
                const Text('전체 토론 시간', style: _summaryTextStyle),
                const SizedBox(width: 14),
                Text(
                  '$totalMinutes',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 20,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 14),
                const Text('분', style: _summaryTextStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const _summaryTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _ReasonItem extends StatelessWidget {
  const _ReasonItem({required this.index, required this.reason});

  final int index;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReason extends StatelessWidget {
  const _EmptyReason();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '작성된 근거가 없습니다.',
        style: TextStyle(
          color: AppColors.textSubtle,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({required this.onCancel, required this.onConfirm});

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: '취소',
              onTap: onCancel,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              foregroundColor: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label: '토론하기',
              onTap: onConfirm,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF526BFF), AppColors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.decoration,
    required this.foregroundColor,
  });

  final String label;
  final VoidCallback onTap;
  final BoxDecoration decoration;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 52,
          decoration: decoration,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
