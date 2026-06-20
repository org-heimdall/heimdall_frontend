import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/community.dart';
import '../../domain/entities/debate_turn.dart';
import '../providers/community_providers.dart';
import '../widgets/debate_message_input.dart';
import '../widgets/debate_turn_card.dart';
import '../widgets/heimdall_logo.dart';

class DebateSessionScreen extends ConsumerStatefulWidget {
  const DebateSessionScreen({required this.community, super.key});

  final Community community;

  @override
  ConsumerState<DebateSessionScreen> createState() =>
      _DebateSessionScreenState();
}

class _DebateSessionScreenState extends ConsumerState<DebateSessionScreen> {
  final _messageController = TextEditingController();
  late final List<DebateTurn> _turns;
  DebateStage _stage = DebateStage.rebuttalQuestion;
  int _remainingSeconds = 180;

  @override
  void initState() {
    super.initState();
    _turns = ref.read(communityRepositoryProvider).getTurns(widget.community);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HeimdallBackButton(),
        title: Text(
          widget.community.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                context.go('/communities/${widget.community.id}/debate/result'),
            child: const Text('종료'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            DebateTimerPanel(
              stage: _stage,
              remainingSeconds: _remainingSeconds,
              isMyTurn: true,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _turns.length,
                itemBuilder: (context, index) {
                  final turn = _turns[index];
                  return DebateTurnCard(
                    turn: turn,
                    compact: true,
                    alignBySide: true,
                  );
                },
              ),
            ),
            DebateMessageInput(controller: _messageController, onSend: _send),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _turns.add(
        DebateTurn(
          stage: _stage,
          side: DebateSide.pro,
          speaker: '나',
          content: text,
          remainingSeconds: _remainingSeconds,
        ),
      );
      _messageController.clear();
      _stage = _stage == DebateStage.rebuttalQuestion
          ? DebateStage.closing
          : DebateStage.rebuttalQuestion;
      _remainingSeconds = _stage.limitSeconds;
    });
  }
}
