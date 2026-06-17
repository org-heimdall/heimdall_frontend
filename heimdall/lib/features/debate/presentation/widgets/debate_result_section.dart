import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'heimdall_card.dart';

class DebateResultSection extends StatelessWidget {
  const DebateResultSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return HeimdallCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: DefaultTextStyle(
        style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class DebateResultBullet extends StatelessWidget {
  const DebateResultBullet(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.accent)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
