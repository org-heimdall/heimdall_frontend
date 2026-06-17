import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debate_room.dart';
import '../providers/debate_providers.dart';
import '../widgets/category_chip.dart';
import '../widgets/debate_list_header.dart';
import '../widgets/debate_room_card.dart';

class DebateListScreen extends ConsumerStatefulWidget {
  const DebateListScreen({super.key});

  @override
  ConsumerState<DebateListScreen> createState() => _DebateListScreenState();
}

class _DebateListScreenState extends ConsumerState<DebateListScreen> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(debateFilterProvider);
    final rooms = ref.watch(debateRoomsProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DebateListHeader(
                          isSearching: _isSearching,
                          onSearchTap: () =>
                              setState(() => _isSearching = !_isSearching),
                          onQueryChanged: (value) {
                            ref
                                .read(debateFilterProvider.notifier)
                                .setQuery(value);
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: DebateCategory.values.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final category = DebateCategory.values[index];
                              return DebateCategoryChip(
                                category: category,
                                selected: category == filter.category,
                                onTap: () {
                                  ref
                                      .read(debateFilterProvider.notifier)
                                      .setCategory(category);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '총 ${rooms.length}건',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {},
                                iconAlignment: IconAlignment.end,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                ),
                                label: const Text('추천순'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textMuted,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                if (rooms.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        '조건에 맞는 토론방이 없습니다.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList.separated(
                      itemCount: rooms.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return DebateRoomCard(
                          room: room,
                          onTap: () => context.push('/debates/${room.id}'),
                        );
                      },
                    ),
                  ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 112,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x00191C20), AppColors.background],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: () async {
            await context.push('/debates/new');
          },
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          shape: const CircleBorder(),
          tooltip: '토론방 생성',
          child: const Icon(Icons.add_rounded, size: 38),
        ),
      ),
    );
  }
}
