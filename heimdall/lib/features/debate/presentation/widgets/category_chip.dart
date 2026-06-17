import 'package:flutter/material.dart';

import '../../domain/entities/debate_room.dart';
import 'debate_tabs.dart';

class DebateCategoryChip extends StatelessWidget {
  const DebateCategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final DebateCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HeimdallTab(label: category.label, selected: selected, onTap: onTap);
  }
}
