import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DebateProgressStep {
  const DebateProgressStep({required this.label, required this.durationLabel});

  final String label;
  final String durationLabel;
}

class DebateProgressSheet extends StatelessWidget {
  const DebateProgressSheet({
    required this.steps,
    required this.currentStepIndex,
    required this.onClose,
    super.key,
  });

  final List<DebateProgressStep> steps;
  final int currentStepIndex;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: Container(
          height: 444,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '토론 진행 상황',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      left: 2,
                      top: 6,
                      bottom: 22,
                      child: _ProgressRail(
                        stepsCount: steps.length,
                        currentStepIndex: currentStepIndex,
                      ),
                    ),
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: steps.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _ProgressStepRow(
                          step: steps[index],
                          state: _stateFor(index),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ProgressStepState _stateFor(int index) {
    if (index < currentStepIndex) {
      return _ProgressStepState.completed;
    }
    if (index == currentStepIndex) {
      return _ProgressStepState.current;
    }
    return _ProgressStepState.pending;
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail({
    required this.stepsCount,
    required this.currentStepIndex,
  });

  final int stepsCount;
  final int currentStepIndex;

  @override
  Widget build(BuildContext context) {
    final completedRatio = stepsCount <= 1
        ? 0.0
        : (currentStepIndex / (stepsCount - 1)).clamp(0.0, 1.0);

    return SizedBox(
      width: 6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final completedHeight = constraints.maxHeight * completedRatio;

          return Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 6,
                height: constraints.maxHeight,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              Container(
                width: 6,
                height: completedHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF42E3FF),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _ProgressStepState { completed, current, pending }

class _ProgressStepRow extends StatelessWidget {
  const _ProgressStepRow({required this.step, required this.state});

  final DebateProgressStep step;
  final _ProgressStepState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _ProgressStepState.current => AppColors.accent,
      _ProgressStepState.completed => AppColors.textSecondary,
      _ProgressStepState.pending => AppColors.textMuted,
    };
    final dotColor = switch (state) {
      _ProgressStepState.current => AppColors.accent,
      _ProgressStepState.completed => const Color(0xFF42E3FF),
      _ProgressStepState.pending => AppColors.textMuted,
    };

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  step.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                step.durationLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
