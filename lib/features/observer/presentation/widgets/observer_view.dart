import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';

class ObserverView extends StatefulWidget {
  const ObserverView({
    required this.items,
    this.isLoading = false,
    this.errorMessage,
    this.emptyMessage = '아직 확정된 토론 발언이 없습니다.',
    this.onRetry,
    this.onClose,
    this.onVote,
    super.key,
  });

  final List<ObserverCommentItem> items;
  final bool isLoading;
  final String? errorMessage;
  final String emptyMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final ObserverVoteCallback? onVote;

  @override
  State<ObserverView> createState() => _ObserverViewState();
}

class _ObserverViewState extends State<ObserverView> {
  static const _panelMaxWidth = 402.0;
  static const _initialHeight = 370.0;
  static const _minimumHeight = 180.0;
  static const _initialTop = 105.0;
  static const _headerHeight = 48.0;
  static const _resizeAreaHeight = 22.0;

  Offset? _position;
  double _panelHeight = _initialHeight;
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant ObserverView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length > oldWidget.items.length) {
      _scrollToLatestItem();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = math.min(_panelMaxWidth, constraints.maxWidth);
        final initialLeft = (constraints.maxWidth - panelWidth) / 2;
        final titleAreaTop = MediaQuery.paddingOf(context).top;
        final position = _clampPosition(
          _position ?? Offset(initialLeft, _initialTop),
          constraints,
          panelWidth,
          _panelHeight,
          titleAreaTop,
        );
        final maxHeight = math.max(
          _minimumHeight,
          constraints.maxHeight - position.dy,
        );
        final panelHeight = _panelHeight.clamp(_minimumHeight, maxHeight);

        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              width: panelWidth,
              height: panelHeight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF12161A),
                    borderRadius: BorderRadius.circular(20),
                    border: const Border(
                      bottom: BorderSide(color: Color(0x33000000), width: 10),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: _headerHeight,
                        bottom: _resizeAreaHeight,
                        child: _buildContent(),
                      ),
                      Positioned(
                        left: 0,
                        right: 56,
                        top: 0,
                        height: 30,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.move,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanUpdate: (details) {
                              setState(() {
                                _position = _clampPosition(
                                  position + details.delta,
                                  constraints,
                                  panelWidth,
                                  panelHeight,
                                  titleAreaTop,
                                );
                              });
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 2,
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: widget.onClose,
                          icon: SvgPicture.asset(
                            'assets/figma/observer_close.svg',
                            width: 16,
                            height: 16,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: '닫기',
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: _resizeAreaHeight,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeUpDown,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragUpdate: (details) {
                              setState(() {
                                _panelHeight = (_panelHeight + details.delta.dy)
                                    .clamp(_minimumHeight, maxHeight);
                              });
                            },
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: (panelWidth - 81) / 2,
                        bottom: 2,
                        width: 81,
                        height: 4,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.textMuted,
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: widget.onRetry, child: const Text('다시 시도')),
            ],
          ],
        ),
      );
    }

    if (widget.items.isEmpty) {
      return Center(
        child: Text(
          widget.emptyMessage,
          style: const TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(11, 4, 23, 8),
      itemCount: widget.items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 22),
      itemBuilder: (context, index) {
        return _ObserverCommentTile(
          key: ValueKey('${widget.items[index].userName}-$index'),
          item: widget.items[index],
          onVote: widget.onVote,
        );
      },
    );
  }

  void _scrollToLatestItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Offset _clampPosition(
    Offset position,
    BoxConstraints constraints,
    double panelWidth,
    double panelHeight,
    double minimumTop,
  ) {
    final maxLeft = math.max(0.0, constraints.maxWidth - panelWidth);
    final maxTop = math.max(0.0, constraints.maxHeight - panelHeight);
    final minTop = math.min(minimumTop, maxTop);
    return Offset(
      position.dx.clamp(0.0, maxLeft),
      position.dy.clamp(minTop, maxTop),
    );
  }
}

class ObserverCommentItem {
  const ObserverCommentItem({
    this.turnId,
    required this.userName,
    required this.content,
    required this.likes,
    required this.dislikes,
    this.isHost = false,
    this.avatarUrl,
  });

  final String? turnId;
  final String userName;
  final String content;
  final int likes;
  final int dislikes;
  final bool isHost;
  final String? avatarUrl;
}

enum ObserverVoteType { like, dislike }

class ObserverVoteResult {
  const ObserverVoteResult({
    required this.likes,
    required this.dislikes,
    required this.selectedVote,
  });

  final int likes;
  final int dislikes;
  final ObserverVoteType? selectedVote;
}

typedef ObserverVoteCallback =
    Future<ObserverVoteResult> Function(String turnId, ObserverVoteType? vote);

class _ObserverCommentTile extends StatefulWidget {
  const _ObserverCommentTile({required this.item, this.onVote, super.key});

  final ObserverCommentItem item;
  final ObserverVoteCallback? onVote;

  @override
  State<_ObserverCommentTile> createState() => _ObserverCommentTileState();
}

class _ObserverCommentTileState extends State<_ObserverCommentTile> {
  static const _contentStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
  );

  bool _expanded = false;
  ObserverVoteType? _selectedVote;
  bool _isVoting = false;
  late int _likes = widget.item.likes;
  late int _dislikes = widget.item.dislikes;

  @override
  void didUpdateWidget(covariant _ObserverCommentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isVoting && oldWidget.item.turnId == widget.item.turnId) {
      _likes = widget.item.likes;
      _dislikes = widget.item.dislikes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(child: _ObserverAvatar(item: item)),
            if (item.isHost)
              const Positioned(
                left: 16,
                bottom: -2,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFFCC00),
                  size: 18,
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final exceedsFiveLines = _exceedsFiveLines(
                context,
                constraints.maxWidth,
                item.content,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.userName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    maxLines: _expanded ? null : 5,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: _contentStyle,
                  ),
                  const SizedBox(height: 10),
                  if (exceedsFiveLines) ...[
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expanded = !_expanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _expanded ? '접기' : '자세히 보기',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _VoteCount(
                          icon: Icons.thumb_up_alt_rounded,
                          count: _likes,
                          selected: _selectedVote == ObserverVoteType.like,
                          onTap: _canVote
                              ? () => _toggleVote(ObserverVoteType.like)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        _VoteCount(
                          icon: Icons.thumb_down_alt_rounded,
                          count: _dislikes,
                          selected: _selectedVote == ObserverVoteType.dislike,
                          onTap: _canVote
                              ? () => _toggleVote(ObserverVoteType.dislike)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  bool get _canVote =>
      !_isVoting && widget.item.turnId != null && widget.onVote != null;

  Future<void> _toggleVote(ObserverVoteType vote) async {
    final requestedVote = _selectedVote == vote ? null : vote;
    setState(() => _isVoting = true);

    try {
      final result = await widget.onVote!(widget.item.turnId!, requestedVote);
      if (!mounted) return;
      setState(() {
        _likes = result.likes;
        _dislikes = result.dislikes;
        _selectedVote = result.selectedVote;
      });
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('투표를 반영하지 못했습니다.')));
    } finally {
      if (mounted) {
        setState(() => _isVoting = false);
      }
    }
  }

  bool _exceedsFiveLines(
    BuildContext context,
    double maxWidth,
    String content,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: content, style: _contentStyle),
      maxLines: 5,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }
}

class _ObserverAvatar extends StatelessWidget {
  const _ObserverAvatar({required this.item});

  final ObserverCommentItem item;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = item.avatarUrl?.trim();

    return SizedBox(
      width: 36,
      height: 36,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? _ObserverAvatarFallback(item: item)
          : Image.network(
              avatarUrl,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, _, _) => _ObserverAvatarFallback(item: item),
            ),
    );
  }
}

class _ObserverAvatarFallback extends StatelessWidget {
  const _ObserverAvatarFallback({required this.item});

  final ObserverCommentItem item;

  @override
  Widget build(BuildContext context) {
    final normalizedName = item.userName.trim();
    final initial = normalizedName.isEmpty
        ? '?'
        : normalizedName.characters.first;
    return ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _VoteCount extends StatelessWidget {
  const _VoteCount({
    required this.icon,
    required this.count,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
