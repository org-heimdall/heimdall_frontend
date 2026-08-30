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
    this.mineOnLeft = false,
    this.messageHorizontalOffset = 0,
    this.messageHorizontalStretch = 1,
    super.key,
  });

  final ChatMessage message;
  final bool isMine;
  final Widget? avatar;
  final Widget? trailing;
  final VoidCallback? onRetry;
  final bool mineOnLeft;
  final double messageHorizontalOffset;
  final double messageHorizontalStretch;

  @override
  Widget build(BuildContext context) {
    if (message.authorId == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SizedBox(
          width: double.infinity,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            ),
            child: Container(
              key: ValueKey('${message.id}:${message.text}'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }
    final maxMessageWidth = isMine
        ? MediaQuery.sizeOf(context).width - 16 * 2 - 72 - 30
        : MediaQuery.sizeOf(context).width - 16 * 2 - 36 - 8 - 32 - 30;
    final messageBodyContent = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxMessageWidth),
      child: Column(
        crossAxisAlignment: mineOnLeft
            ? (isMine ? CrossAxisAlignment.start : CrossAxisAlignment.end)
            : (isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start),
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

    final messageBody = Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..translateByDouble(messageHorizontalOffset, 0, 0, 1)
        ..scaleByDouble(messageHorizontalStretch, 1, 1, 1),
      child: messageBodyContent,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? (mineOnLeft ? MainAxisAlignment.start : MainAxisAlignment.end)
            : (mineOnLeft ? MainAxisAlignment.end : MainAxisAlignment.start),
        children: [
          if (!isMine && mineOnLeft)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                messageBody,
                if (avatar != null) ...[const SizedBox(width: 8), avatar!],
              ],
            )
          else if (!isMine)
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
            Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..translateByDouble(messageHorizontalOffset, 0, 0, 1)
                ..scaleByDouble(messageHorizontalStretch, 1, 1, 1),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}
