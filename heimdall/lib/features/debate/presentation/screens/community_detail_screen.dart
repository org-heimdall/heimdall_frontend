import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';
import '../widgets/community_status_label.dart';
import '../widgets/debate_elapsed_time.dart';
import '../widgets/heimdall_controls.dart';
import '../widgets/heimdall_logo.dart';

class CommunityDetailScreen extends StatelessWidget {
  const CommunityDetailScreen({required this.community, super.key});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final hostReasons = community.hostReasons.isEmpty
        ? ['호스트가 등록한 근거가 없습니다.']
        : community.hostReasons;

    return Scaffold(
      appBar: AppBar(
        leading: const HeimdallBackButton(),
        title: const Text(
          '커뮤니티 상세',
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 132),
          children: [
            _CommunityDebateCard(community: community),
            const SizedBox(height: 48),
            const _SectionTitle('호스트'),
            const SizedBox(height: 16),
            _HostSummary(host: community.host),
            const SizedBox(height: 48),
            const _SectionTitle('호스트 주장'),
            const SizedBox(height: 16),
            _ReadonlyBox(
              text: community.hostClaim.isEmpty
                  ? '호스트가 등록한 주장이 없습니다.'
                  : community.hostClaim,
            ),
            const SizedBox(height: 48),
            const _SectionTitle('호스트 근거'),
            const SizedBox(height: 16),
            for (var i = 0; i < hostReasons.length; i++) ...[
              _ReasonBox(index: i + 1, text: hostReasons[i]),
              if (i != hostReasons.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      bottomNavigationBar: HeimdallBottomActionBar(
        label: '커뮤니티 입장하기',
        onPressed: () => context.push('/communities/${community.id}/chat'),
        includeSafeArea: false,
      ),
    );
  }
}

class _CommunityDebateCard extends StatelessWidget {
  const _CommunityDebateCard({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        gradient: const RadialGradient(
          center: Alignment(0.7, -0.75),
          radius: 1.65,
          colors: [Color(0x332C2F70), AppColors.card],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CommunityStatusLabel.fromStatus(status: community.status),
              const Spacer(),
              _ObserverPill(count: community.observerCount),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            community.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          DebateElapsedTime(minutes: community.elapsedMinutes),
          const SizedBox(height: 16),
          Text(
            community.topic,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _CardDivider(),
          const SizedBox(height: 14),
          Row(
            children: [
              _HostInline(host: community.host),
              const Spacer(),
              _CardMetaChip(label: community.category.label),
              const SizedBox(width: 6),
              _CardMetaChip(
                label: '${community.rounds}라운드',
                iconAsset: AppAssets.repeatIcon,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ObserverPill extends StatelessWidget {
  const _ObserverPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 7, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.divider);
  }
}

class _HostInline extends StatelessWidget {
  const _HostInline({required this.host});

  final CommunityHost host;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(host.avatarColor),
            child: Text(
              host.name.characters.first,
              style: const TextStyle(
                color: AppColors.background,
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '호스트',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  host.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMetaChip extends StatelessWidget {
  const _CardMetaChip({required this.label, this.iconAsset});

  final String label;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            SvgPicture.asset(
              iconAsset!,
              width: 14,
              height: 14,
              colorFilter: const ColorFilter.mode(
                AppColors.textMuted,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
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

class _HostSummary extends StatelessWidget {
  const _HostSummary({required this.host});

  final CommunityHost host;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Color(host.avatarColor),
            child: Text(
              host.name.characters.first,
              style: const TextStyle(
                color: AppColors.background,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  host.name,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '호스트',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadonlyBox extends StatelessWidget {
  const _ReadonlyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ReasonBox extends StatelessWidget {
  const _ReasonBox({required this.index, required this.text});

  final int index;
  final String text;

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
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
