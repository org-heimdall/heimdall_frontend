import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class StepPopUp extends StatelessWidget {
  const StepPopUp({
    required this.steps,
    this.currentIndex = 0,
    this.completedCount = 0,
    this.onClose,
    super.key,
  });

  final List<StepPopupItem> steps;
  final int currentIndex;
  final int completedCount;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 370,
      height: 444,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
            tooltip: '닫기',
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              '토론 진행 상황',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 20,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  left: 2,
                  top: 6,
                  bottom: 10,
                  child: Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  left: 2,
                  top: 6,
                  child: FractionallySizedBox(
                    heightFactor: steps.isEmpty
                        ? 0
                        : (completedCount / steps.length).clamp(0, 1),
                    child: Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF42E3FF),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _StepRow(item: steps[i], state: _stateFor(i)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StepState _stateFor(int index) {
    if (index < completedCount) {
      return _StepState.completed;
    }
    if (index == currentIndex) {
      return _StepState.current;
    }
    return _StepState.pending;
  }
}

class StepPopupItem {
  const StepPopupItem({required this.label, required this.duration});

  final String label;
  final String duration;
}

enum _StepState { completed, current, pending }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.item, required this.state});

  final StepPopupItem item;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.completed => AppColors.textSecondary,
      _StepState.current => AppColors.accent,
      _StepState.pending => AppColors.textMuted,
    };
    final dotColor = switch (state) {
      _StepState.completed => const Color(0xFF42E3FF),
      _StepState.current => AppColors.accent,
      _StepState.pending => AppColors.textMuted,
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
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                item.duration,
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
