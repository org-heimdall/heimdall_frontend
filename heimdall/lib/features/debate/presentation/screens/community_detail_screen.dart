import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community.dart';
import '../widgets/community_status_label.dart';
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
        onPressed: () => context.push('/communities/${community.id}/debate'),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
              _CategoryChip(label: community.category.label),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            community.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            community.topic,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _InfoGrid(
            rounds: community.rounds,
            totalMinutes: community.rounds * 6 + 4,
            isPublic: community.isPublic,
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.rounds,
    required this.totalMinutes,
    required this.isPublic,
  });

  final int rounds;
  final int totalMinutes;
  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoTile(label: '라운드', value: '$rounds개'),
        const SizedBox(width: 8),
        _InfoTile(label: '전체 시간', value: '$totalMinutes분'),
        const SizedBox(width: 8),
        _InfoTile(label: '공개', value: isPublic ? '공개' : '비공개'),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
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
