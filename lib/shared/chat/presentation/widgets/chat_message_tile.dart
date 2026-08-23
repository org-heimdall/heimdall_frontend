import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_message.dart';

class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({
    required this.message,
    required this.isMine,
    this.avatar,
    this.trailing,
    this.onRetry,
    super.key,
  });

  final ChatMessage message;
  final bool isMine;
  final Widget? avatar;
  final Widget? trailing;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final maxMessageWidth = isMine
        ? MediaQuery.sizeOf(context).width - 16 * 2 - 72 - 30
        : MediaQuery.sizeOf(context).width - 16 * 2 - 36 - 8 - 32 - 30;
    final messageBody = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxMessageWidth),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            Text(
              message.authorName,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
          ],
          AnimatedOpacity(
            opacity: message.deliveryStatus == ChatMessageDeliveryStatus.pending
                ? 0.65
                : 1,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ),
          if (message.deliveryStatus == ChatMessageDeliveryStatus.failed) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Text(
                  '전송 실패 · 다시 보내기',
                  style: TextStyle(
                    color: AppColors.con,
                    fontSize: 11,
                    height: 1.35,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (avatar != null) ...[avatar!, const SizedBox(width: 8)],
                messageBody,
              ],
            )
          else
            messageBody,
          if (!isMine && trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}
