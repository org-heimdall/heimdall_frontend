import 'package:flutter/material.dart';

import '../../../../shared/presentation/widgets/confirmation_dialog.dart';

class DebateForfeitDialog extends StatelessWidget {
  const DebateForfeitDialog({
    required this.onCancel,
    required this.onForfeit,
    super.key,
  });

  final VoidCallback onCancel;
  final VoidCallback onForfeit;

  @override
  Widget build(BuildContext context) {
    return AppConfirmationDialog(
      icon: Icons.error_outline_rounded,
      title: '정말 기권하시겠습니까?',
      description: '토론방을 나가시면 즉시 패배 처리됩니다.',
      cancelLabel: '아니오',
      confirmLabel: '나가기',
      onCancel: onCancel,
      onConfirm: onForfeit,
    );
  }
}
