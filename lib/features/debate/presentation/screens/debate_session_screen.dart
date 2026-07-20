import 'package:flutter/material.dart';

import '../../domain/entities/community.dart';
import '../widgets/debate_room.dart';

class DebateSessionScreen extends StatelessWidget {
  const DebateSessionScreen({required this.community, super.key});

  final Community community;

  @override
  Widget build(BuildContext context) {
    return DebateRoom(
      community: community,
      isHost: community.isOwnedByCurrentUser || community.host.name == '나',
    );
  }
}
