import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DebateProcessingDialog extends StatelessWidget {
  const DebateProcessingDialog({
    required this.status,
    required this.canRetry,
    required this.retrying,
    required this.onRetry,
    super.key,
  });

  final String status;
  final bool canRetry;
  final bool retrying;
  final VoidCallback onRetry;

  bool get _isJudging => status == 'JUDGING';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 354),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isJudging ? 'AI 판정 중' : '토론 내용 정리 중',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isJudging
                    ? '양측의 토론 내용을 바탕으로\n최종 판정 결과를 생성하고 있어요.\n잠시만 기다려 주세요.'
                    : '양측의 발언을 분석하고 근거를 확인하고 있어요.\n잠시만 기다려 주세요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  height: 1.5,
                  letterSpacing: -0.3,
                ),
              ),
              if (canRetry) ...[
                const SizedBox(height: 20),
                const Text(
                  '판정 작업이 평소보다 오래 걸리고 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: retrying ? null : onRetry,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primarySoft,
                      disabledBackgroundColor: AppColors.surfaceElevated,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: retrying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '재시도',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
