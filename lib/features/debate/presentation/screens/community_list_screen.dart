import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';
import '../providers/community_providers.dart';
import '../widgets/community_category_chip.dart';
import '../widgets/community_list_header.dart';
import '../widgets/community_card.dart';

class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});

  @override
  ConsumerState<CommunityListScreen> createState() =>
      _CommunityListScreenState();
}

class _CommunityListScreenState extends ConsumerState<CommunityListScreen> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(communityFilterProvider);
    final rooms = ref.watch(communitiesProvider);

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
                        CommunityListHeader(
                          isSearching: _isSearching,
                          onSearchTap: () =>
                              setState(() => _isSearching = !_isSearching),
                          onQueryChanged: (value) {
                            ref
                                .read(communityFilterProvider.notifier)
                                .setQuery(value);
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: CommunityCategory.values.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final category = CommunityCategory.values[index];
                              return CommunityCategoryChip(
                                category: category,
                                selected: category == filter.category,
                                onTap: () {
                                  ref
                                      .read(communityFilterProvider.notifier)
                                      .setCategory(category);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '추천순',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 13,
                                          height: 1.35,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.textMuted,
                                        size: 16,
                                      ),
                                    ],
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
                        '조건에 맞는 커뮤니티가 없습니다.',
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
                        final community = rooms[index];
                        return CommunityCard(
                          community: community,
                          onTap: () =>
                              context.push('/communities/${community.id}'),
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
            await context.push('/communities/new');
          },
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          shape: const CircleBorder(),
          tooltip: '커뮤니티 생성',
          child: const Icon(Icons.add_rounded, size: 38),
        ),
      ),
    );
  }
}
