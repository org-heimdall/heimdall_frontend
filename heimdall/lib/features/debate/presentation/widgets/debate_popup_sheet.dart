import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import 'heimdall_controls.dart';

class DebatePopupSheet extends StatelessWidget {
  const DebatePopupSheet({
    required this.userName,
    required this.score,
    required this.claim,
    required this.reasons,
    this.role = DebatePopupRole.participant,
    this.onClose,
    this.onDebate,
    super.key,
  });

  final String userName;
  final int score;
  final String claim;
  final List<String> reasons;
  final DebatePopupRole role;
  final VoidCallback? onClose;
  final VoidCallback? onDebate;

  bool get _isHost => role == DebatePopupRole.host;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 370,
          height: _isHost ? 524 : 540,
          color: AppColors.surface,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: onClose,
                              icon: const Icon(Icons.close_rounded),
                              color: AppColors.textMuted,
                              tooltip: '닫기',
                            ),
                          ),
                          _PopupUserSummary(userName: userName, score: score),
                          const SizedBox(height: 24),
                          _ReadonlyField(label: '주장', text: claim),
                          const SizedBox(height: 24),
                          _ReasonList(reasons: reasons),
                        ],
                      ),
                    ),
                  ),
                  if (_isHost)
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.all(16),
                      child: HeimdallPrimaryButton(
                        label: '토론하기',
                        onPressed: onDebate,
                      ),
                    ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: _isHost ? 89 : 0,
                child: IgnorePointer(
                  child: Container(
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x0022282D), AppColors.surface],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum DebatePopupRole { host, participant }

class _PopupUserSummary extends StatelessWidget {
  const _PopupUserSummary({required this.userName, required this.score});

  final String userName;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ClipOval(
            child: Image.asset(
              AppAssets.avatarBlue,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(4, 2, 6, 2),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AppAssets.trophyIcon,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
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

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
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
      ],
    );
  }
}

class _ReasonList extends StatelessWidget {
  const _ReasonList({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '근거',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < reasons.length; i++) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySoft,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reasons[i],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (i != reasons.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
