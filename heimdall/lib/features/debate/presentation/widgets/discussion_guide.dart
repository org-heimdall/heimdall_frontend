import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DiscussionGuide extends StatelessWidget {
  const DiscussionGuide({
    this.lines = const [
      '토론자가 결정되었습니다.',
      '10초 뒤, 비프로스트의 문이 열립니다.',
      '기조 발언을 탐색하거나 상대방과 인사를 나누세요.',
    ],
    super.key,
  });

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final line in lines)
              Text(
                line,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
