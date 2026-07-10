import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CommunityOpinionDraft {
  const CommunityOpinionDraft({required this.claim, required this.reasons});

  final String claim;
  final List<String> reasons;
}

class CommunityOpinionSheet extends StatefulWidget {
  const CommunityOpinionSheet({this.onSubmit, super.key});

  final FutureOr<void> Function(CommunityOpinionDraft draft)? onSubmit;

  @override
  State<CommunityOpinionSheet> createState() => _CommunityOpinionSheetState();
}

class _CommunityOpinionSheetState extends State<CommunityOpinionSheet> {
  final _claimController = TextEditingController();
  final List<TextEditingController> _reasonControllers = [
    TextEditingController(),
  ];

  bool _submitting = false;

  bool get _canSubmit =>
      _claimController.text.trim().isNotEmpty && !_submitting;

  @override
  void initState() {
    super.initState();
    _claimController.addListener(_refresh);
  }

  @override
  void dispose() {
    _claimController
      ..removeListener(_refresh)
      ..dispose();
    for (final controller in _reasonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight =
        MediaQuery.sizeOf(context).height -
        keyboardInset -
        MediaQuery.paddingOf(context).top;
    final sheetHeight = math.min(578.0, availableHeight);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: ColoredBox(
          color: AppColors.background,
          child: SizedBox(
            height: sheetHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: _SheetHandle()),
                        const SizedBox(height: 40),
                        const _SheetHeader(),
                        const SizedBox(height: 40),
                        _ClaimField(controller: _claimController),
                        const SizedBox(height: 40),
                        _ReasonFields(
                          controllers: _reasonControllers,
                          onAdd: _addReason,
                          onChanged: _refresh,
                        ),
                      ],
                    ),
                  ),
                ),
                _SubmitBar(
                  enabled: _canSubmit,
                  submitting: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addReason() {
    setState(() {
      _reasonControllers.add(TextEditingController());
    });
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    final draft = CommunityOpinionDraft(
      claim: _claimController.text.trim(),
      reasons: [
        for (final controller in _reasonControllers)
          if (controller.text.trim().isNotEmpty) controller.text.trim(),
      ],
    );

    try {
      await widget.onSubmit?.call(draft);
      if (mounted) {
        Navigator.pop(context, draft);
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 81,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기조 발언 작성하기',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 22,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '나의 주장을 입력해 호스트에게 토론 참여 의사를 표하세요.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
            height: 1.5,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _ClaimField extends StatelessWidget {
  const _ClaimField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _OpinionFieldGroup(
      label: '나의 주장',
      required: true,
      child: _OpinionTextField(
        controller: controller,
        hintText: '토론 주제에 대한 나의 주장을 한 줄 요약해주세요.',
        textInputAction: TextInputAction.next,
      ),
    );
  }
}

class _ReasonFields extends StatelessWidget {
  const _ReasonFields({
    required this.controllers,
    required this.onAdd,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _OpinionFieldGroup(
      label: '근거',
      child: Column(
        children: [
          for (var i = 0; i < controllers.length; i++) ...[
            _ReasonTextField(
              number: i + 1,
              controller: controllers[i],
              onChanged: onChanged,
            ),
            const SizedBox(height: 16),
          ],
          _AddReasonButton(onTap: onAdd),
        ],
      ),
    );
  }
}

class _OpinionFieldGroup extends StatelessWidget {
  const _OpinionFieldGroup({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFA1AEFF)),
                ),
            ],
          ),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _ReasonTextField extends StatelessWidget {
  const _ReasonTextField({
    required this.number,
    required this.controller,
    required this.onChanged,
  });

  final int number;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              '$number',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '주장을 뒷받침할 근거를 작성해주세요.',
                hintMaxLines: 1,
                hintStyle: TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpinionTextField extends StatelessWidget {
  const _OpinionTextField({
    required this.controller,
    required this.hintText,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        textInputAction: textInputAction,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textSubtle,
            fontSize: 15,
            height: 1.5,
          ),
          hintMaxLines: 1,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _AddReasonButton extends StatelessWidget {
  const _AddReasonButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '근거 추가',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _DashedBorderPainter(color: AppColors.textMuted, radius: 12),
          child: const SizedBox(
            height: 52,
            width: double.infinity,
            child: Icon(
              Icons.add_rounded,
              color: AppColors.textMuted,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.enabled,
    required this.submitting,
    required this.onPressed,
  });

  final bool enabled;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 105,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surface)),
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.surfaceElevated,
          foregroundColor: AppColors.textSecondary,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size.fromHeight(57),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('발언 작성하기'),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashWidth = 3.0;
      const dashGap = 3.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
