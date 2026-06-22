import 'package:flutter/material.dart';

import '../../domain/entities/community.dart';
import '../widgets/heimdall_logo.dart';

class DebateSessionScreen extends StatelessWidget {
  const DebateSessionScreen({required this.community, super.key});

  final Community community;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HeimdallBackButton(),
        title: Text(
          community.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: const Center(child: Text('토론 채팅방')),
    );
  }
}
