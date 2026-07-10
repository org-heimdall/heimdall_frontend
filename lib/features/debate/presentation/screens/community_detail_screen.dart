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
        toolbarHeight: 65,
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 128),
          children: [
            _CommunityDebateCard(community: community),
            const SizedBox(height: 24),
            const _SectionTitle('호스트'),
            const SizedBox(height: 14),
            _HostSummary(host: community.host),
            const SizedBox(height: 34),
            const _SectionTitle('호스트 주장'),
            const SizedBox(height: 16),
            _ClaimBox(
              text: community.hostClaim.isEmpty
                  ? '호스트가 등록한 주장이 없습니다.'
                  : community.hostClaim,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('호스트 근거'),
            const SizedBox(height: 16),
            for (var i = 0; i < hostReasons.length; i++) ...[
              _ReasonBox(index: i + 1, text: hostReasons[i]),
              if (i != hostReasons.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      bottomNavigationBar: HeimdallBottomActionBar(
        label: '커뮤니티 입장',
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
      constraints: const BoxConstraints(minHeight: 189),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 17),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityStatusLabel.fromStatus(status: community.status),
              const Spacer(),
              _StackedParticipants(community: community),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            community.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          FractionallySizedBox(
            widthFactor: 0.92,
            alignment: Alignment.centerLeft,
            child: Text(
              community.topic,
              softWrap: true,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 15,
            runSpacing: 8,
            children: [
              _CardMetaChip(
                label: '${community.rounds}라운드',
                icon: Icons.repeat_rounded,
              ),
              _CardMetaChip(label: community.category.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _StackedParticipants extends StatelessWidget {
  const _StackedParticipants({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      Color(community.host.avatarColor),
      if (community.activeDebaters.isNotEmpty)
        Color(community.activeDebaters.first.avatarColor)
      else
        AppColors.primary,
    ];

    return SizedBox(
      width: 44,
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * 16,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardMetaChip extends StatelessWidget {
  const _CardMetaChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final hasIcon = icon != null;

    return Container(
      height: 31,
      width: hasIcon ? null : 65,
      padding: EdgeInsets.fromLTRB(hasIcon ? 6 : 0, 5, hasIcon ? 10 : 0, 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: hasIcon ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: hasIcon
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          if (hasIcon) ...[
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
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
      height: 70.5,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
            child: Text(
              host.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimBox extends StatelessWidget {
  const _ClaimBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 53),
          padding: const EdgeInsets.fromLTRB(46, 14, 18, 14),
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
        ),
        const Positioned(
          left: 14,
          top: 15,
          child: Icon(
            Icons.format_quote_rounded,
            color: AppColors.primarySoft,
            size: 22,
          ),
        ),
      ],
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
      constraints: BoxConstraints(minHeight: text.length > 32 ? 76 : 52),
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
