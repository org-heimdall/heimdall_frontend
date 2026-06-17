import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debate_room.dart';
import '../providers/debate_providers.dart';
import '../widgets/heimdall_card.dart';
import '../widgets/heimdall_controls.dart';
import '../widgets/heimdall_logo.dart';
import '../widgets/side_pill.dart';

class CreateDebateScreen extends ConsumerStatefulWidget {
  const CreateDebateScreen({super.key});

  @override
  ConsumerState<CreateDebateScreen> createState() => _CreateDebateScreenState();
}

class _CreateDebateScreenState extends ConsumerState<CreateDebateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _topicController = TextEditingController();
  DebateCategory _category = DebateCategory.society;
  DebateSide _side = DebateSide.pro;
  int _rounds = 3;
  bool _isPublic = true;

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HeimdallBackButton(),
        title: const Text('토론방 생성'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              HeimdallTextFormField(
                controller: _titleController,
                label: '토론 제목',
                maxLength: 36,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '제목을 입력하세요.' : null,
              ),
              const SizedBox(height: 14),
              HeimdallTextFormField(
                controller: _topicController,
                label: '토론 주제',
                maxLines: 3,
                maxLength: 120,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '주제를 입력하세요.' : null,
              ),
              const SizedBox(height: 18),
              const HeimdallSectionTitle('카테고리'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DebateCategory.values
                    .where((category) => category != DebateCategory.all)
                    .map(
                      (category) => ChoiceChip(
                        label: Text(category.label),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: _category == category
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              const HeimdallSectionTitle('내 입장'),
              const SizedBox(height: 10),
              Row(
                children: [
                  SidePill(
                    side: DebateSide.pro,
                    selected: _side == DebateSide.pro,
                    onTap: () => setState(() => _side = DebateSide.pro),
                  ),
                  const SizedBox(width: 8),
                  SidePill(
                    side: DebateSide.con,
                    selected: _side == DebateSide.con,
                    onTap: () => setState(() => _side = DebateSide.con),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const HeimdallSectionTitle('라운드 수'),
              Slider(
                value: _rounds.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_rounds',
                onChanged: (value) => setState(() => _rounds = value.round()),
              ),
              SwitchListTile(
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('공개 토론'),
                subtitle: const Text('목록에서 다른 사용자가 참여할 수 있습니다.'),
              ),
              const SizedBox(height: 28),
              HeimdallPrimaryButton(label: '토론방 만들기', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final room = ref
        .read(debateRepositoryProvider)
        .createRoom(
          title: _titleController.text.trim(),
          topic: _topicController.text.trim(),
          category: _category,
          side: _side,
          rounds: _rounds,
          isPublic: _isPublic,
        );
    ref.invalidate(debateRoomsProvider);
    context.go('/debates/${room.id}');
  }
}
