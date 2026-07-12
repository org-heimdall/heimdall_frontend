import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';
import '../providers/community_providers.dart';
import '../widgets/debate_tabs.dart';
import '../widgets/heimdall_controls.dart';
import '../widgets/heimdall_labeled_text_field.dart';

class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _claimController = TextEditingController();
  final _reasonControllers = [TextEditingController()];

  CommunityCategory _category = CommunityCategory.politics;
  int _rounds = 3;

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    _claimController.dispose();
    for (final controller in _reasonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          iconSize: 28,
          color: AppColors.textMuted,
          tooltip: '뒤로',
        ),
        leadingWidth: 44,
        titleSpacing: 0,
        title: const Text(
          '토론 커뮤니티 생성',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 22,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _RequiredSectionLabel('토론 테마'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: CommunityCategory.values
                          .where(
                            (category) => category != CommunityCategory.all,
                          )
                          .map(
                            (category) => HeimdallTab(
                              label: category.label,
                              selected: _category == category,
                              variant: HeimdallTabVariant.outline,
                              onTap: () => setState(() => _category = category),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 64),
                    HeimdallLabeledTextField(
                      controller: _topicController,
                      label: '토론 주제 *',
                      hintText: '토론하고자 하는 주제를 작성해주세요.',
                      validator: _required('토론 주제를 입력하세요.'),
                    ),
                    const SizedBox(height: 64),
                    HeimdallLabeledTextField(
                      controller: _descriptionController,
                      label: '토론 설명',
                      hintText: '토론 설명을 작성해주세요.',
                    ),
                    const SizedBox(height: 64),
                    const _RequiredSectionLabel('토론 라운드 개수'),
                    const SizedBox(height: 8),
                    const Text(
                      '참여자의 모든 턴이 끝나면 하나의 라운드가 완료됩니다.\n각 턴은 3분 동안 진행됩니다.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RoundSelector(
                      rounds: _rounds,
                      onIncrement: () => setState(() {
                        if (_rounds < 9) {
                          _rounds += 1;
                        }
                      }),
                      onDecrement: () => setState(() {
                        if (_rounds > 1) {
                          _rounds -= 1;
                        }
                      }),
                    ),
                    const SizedBox(height: 64),
                    HeimdallLabeledTextField(
                      controller: _claimController,
                      label: '나의 주장 *',
                      hintText: '토론 주제에 대한 나의 주장을 한 줄 요약해주세요.',
                      validator: _required('나의 주장을 입력하세요.'),
                    ),
                    const SizedBox(height: 64),
                    const _SectionLabel('근거'),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _reasonControllers.length; i++) ...[
                      _ReasonField(
                        index: i + 1,
                        controller: _reasonControllers[i],
                        validator: i == 0 ? _required('근거를 입력하세요.') : null,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _AddReasonButton(
                      onTap: () => setState(() {
                        _reasonControllers.add(TextEditingController());
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 132),
            ],
          ),
        ),
      ),
      bottomNavigationBar: HeimdallBottomActionBar(
        label: '커뮤니티 생성하기',
        onPressed: _submit,
        includeSafeArea: false,
      ),
    );
  }

  FormFieldValidator<String> _required(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final room = ref
        .read(communityRepositoryProvider)
        .createCommunity(
          title: _topicController.text.trim(),
          topic: _descriptionController.text.trim(),
          category: _category,
          side: DebateSide.pro,
          rounds: _rounds,
          isPublic: true,
          hostClaim: _claimController.text.trim(),
          hostReasons: _reasonControllers
              .map((controller) => controller.text.trim())
              .where((reason) => reason.isNotEmpty)
              .toList(),
        );
    ref.invalidate(communitiesProvider);
    context.go('/communities/${room.id}');
  }
}

class _RequiredSectionLabel extends StatelessWidget {
  const _RequiredSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label ',
        children: const [
          TextSpan(
            text: '*',
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
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 18,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _RoundSelector extends StatelessWidget {
  const _RoundSelector({
    required this.rounds,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int rounds;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = rounds * 6 + 4;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Text('라운드', style: _roundTextStyle),
          const SizedBox(width: 8),
          Column(
            children: [
              _RoundStepperButton(
                onPressed: onIncrement,
                icon: Icons.keyboard_arrow_up_rounded,
              ),
              const SizedBox(height: 8),
              Container(
                width: 52,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$rounds',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _RoundStepperButton(
                onPressed: onDecrement,
                icon: Icons.keyboard_arrow_down_rounded,
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Text('개,', style: _roundTextStyle),
          const SizedBox(width: 12),
          const Text('전체 토론 시간', style: _roundTextStyle),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            height: 60,
            child: Center(
              child: Text(
                '$totalMinutes',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const Text('분', style: _roundTextStyle),
        ],
      ),
    );
  }

  static const _roundTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );
}

class _RoundStepperButton extends StatelessWidget {
  const _RoundStepperButton({required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.primarySoft,
        iconSize: 32,
        padding: EdgeInsets.zero,
        splashRadius: 20,
      ),
    );
  }
}

class _ReasonField extends StatelessWidget {
  const _ReasonField({
    required this.index,
    required this.controller,
    this.validator,
  });

  final int index;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$index',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              decoration: const InputDecoration.collapsed(
                hintText: '주장을 뒷받침할 근거를 작성해주세요.',
                hintStyle: TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddReasonButton extends StatelessWidget {
  const _AddReasonButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: _DashedRoundedBorderPainter(
          color: AppColors.textMuted,
          radius: 12,
        ),
        child: const SizedBox(
          width: double.infinity,
          height: 52,
          child: Icon(Icons.add_rounded, color: AppColors.textMuted, size: 24),
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashGap = 4.0;
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

      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return color != oldDelegate.color || radius != oldDelegate.radius;
  }
}
