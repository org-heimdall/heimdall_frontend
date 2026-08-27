import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    required this.controller,
    required this.onSend,
    required this.hintText,
    this.focusNode,
    this.enabled = true,
    this.maxLength,
    this.leading = const [],
    this.onLimitReached,
    this.maxLines = 1,
    super.key,
  }) : assert(maxLines > 0);

  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSend;
  final String hintText;
  final bool enabled;
  final int? maxLength;
  final List<Widget> leading;
  final VoidCallback? onLimitReached;
  final int maxLines;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleTextChanged);
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.enabled && widget.controller.text.trim().isNotEmpty;
    final isMultiline = widget.maxLines > 1;
    final inputFormatters = widget.maxLength == null
        ? <TextInputFormatter>[]
        : <TextInputFormatter>[
            LengthLimitingTextInputFormatter(widget.maxLength),
          ];

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          color: AppColors.background,
          child: Row(
            crossAxisAlignment: isMultiline
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.center,
            children: [
              for (var index = 0; index < widget.leading.length; index++) ...[
                widget.leading[index],
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          enabled: widget.enabled,
                          minLines: 1,
                          maxLines: widget.maxLines,
                          maxLength: widget.maxLength,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          inputFormatters: inputFormatters,
                          keyboardType: isMultiline
                              ? TextInputType.multiline
                              : TextInputType.text,
                          textInputAction: isMultiline
                              ? TextInputAction.newline
                              : TextInputAction.send,
                          onTapOutside: (_) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.45,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            counterText: '',
                            isCollapsed: true,
                            hintText: widget.hintText,
                            hintStyle: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          onChanged: (value) {
                            final maxLength = widget.maxLength;
                            if (maxLength != null &&
                                value.characters.length >= maxLength) {
                              widget.onLimitReached?.call();
                            }
                          },
                          onSubmitted: (_) {
                            if (!isMultiline && canSend) {
                              widget.onSend();
                            }
                          },
                        ),
                      ),
                      InkWell(
                        onTap: canSend ? widget.onSend : null,
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: canSend
                                ? AppColors.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: canSend
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
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
