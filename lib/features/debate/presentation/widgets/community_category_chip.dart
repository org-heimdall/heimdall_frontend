import 'package:flutter/material.dart';

import '../../domain/entities/community.dart';
import 'debate_tabs.dart';

class CommunityCategoryChip extends StatelessWidget {
  const CommunityCategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final CommunityCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HeimdallTab(label: category.label, selected: selected, onTap: onTap);
  }
}
