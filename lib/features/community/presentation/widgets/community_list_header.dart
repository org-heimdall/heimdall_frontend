import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/presentation/widgets/heimdall_logo.dart';

class CommunityListHeader extends StatelessWidget {
  const CommunityListHeader({
    required this.isSearching,
    required this.onSearchTap,
    required this.onQueryChanged,
    required this.onLogout,
    super.key,
  });

  final bool isSearching;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                const Expanded(child: HeimdallLogo()),
                IconButton(
                  onPressed: onSearchTap,
                  icon: Icon(
                    isSearching ? Icons.close_rounded : Icons.search_rounded,
                  ),
                  color: AppColors.textMuted,
                  tooltip: isSearching ? '검색 닫기' : '검색',
                ),
                IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  color: AppColors.textMuted,
                  tooltip: '로그아웃',
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isSearching
                ? Padding(
                    key: const ValueKey('search'),
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      autofocus: true,
                      onChanged: onQueryChanged,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '토론 주제나 제목 검색',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }
}
