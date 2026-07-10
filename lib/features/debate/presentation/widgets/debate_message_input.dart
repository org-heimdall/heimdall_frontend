import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DebateMessageInput extends StatelessWidget {
  const DebateMessageInput({
    required this.controller,
    required this.onSend,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLength: 1000,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '발언 입력',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send_rounded),
            tooltip: '발언 제출',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              disabledBackgroundColor: AppColors.surface,
              disabledForegroundColor: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
