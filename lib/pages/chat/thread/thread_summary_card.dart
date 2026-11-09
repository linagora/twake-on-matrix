import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/date_time_extension.dart';

/// Card inside the bubble of a thread root: number of messages, then author, text and age of
/// the last reply. It does not repeat the root text, which is right above.
class ThreadSummaryCard extends StatelessWidget {
  const ThreadSummaryCard({
    super.key,
    required this.replyCount,
    this.lastReplyAuthor,
    this.lastReplyText,
    this.lastReplyTime,
    required this.onTap,
    this.unreadCount = 0,
    this.onOwnBubble = false,
  });

  final int replyCount;

  /// Null when no reply is left to show: the card shows the count only.
  final String? lastReplyAuthor;
  final String? lastReplyText;
  final DateTime? lastReplyTime;
  final int unreadCount;

  /// The card sits on a bubble of the user (the paper of the theme) rather
  /// than on a received one (a raised surface).
  final bool onOwnBubble;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    final textStyle = LinagoraTextStyle.material();
    final count = l10n.threadMessagesCount(replyCount);
    final scheme = Theme.of(context).colorScheme;
    final unread = unreadCount > 0;
    final secondary = textStyle.bodySmall.copyWith(color: colors.secondary);
    final last = lastReplyTime == null
        ? null
        : TextSpan(
            style: secondary,
            children: [
              TextSpan(
                text: lastReplyAuthor,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text:
                    ': $lastReplyText · '
                    '${lastReplyTime!.ageFrom(context)}',
              ),
            ],
          );

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: [
        count,
        if (unread) l10n.threadUnreadMessagesCount(unreadCount),
        ?last?.toPlainText(),
      ].join(', '),
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            // Takes the width it is given; shrinks if it is unbounded.
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: onOwnBubble
                  ? scheme.surfaceContainerLowest
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: _LeftBarBorder(
                bar: unread ? colors.primary : colors.outline,
                outline: colors.outline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsetsDirectional.only(end: 6),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    // Its minimum width is its whole text: it never wraps.
                    IntrinsicWidth(
                      child: Text(
                        '$count ›',
                        style: textStyle.bodySmall.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (last != null)
                  Text.rich(last, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 1 px outline with a 3 px bar on the start side (`left` holds the bar,
/// whichever the direction). A [Border] with a wider side
/// cannot be painted with a radius, so this one draws both itself.
class _LeftBarBorder extends Border {
  _LeftBarBorder({required Color bar, required Color outline})
    : super(
        top: BorderSide(color: outline),
        right: BorderSide(color: outline),
        bottom: BorderSide(color: outline),
        left: BorderSide(color: bar, width: 3),
      );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsetsDirectional.fromSTEB(
    left.width,
    top.width,
    right.width,
    bottom.width,
  );

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final rrect = (borderRadius ?? BorderRadius.zero).toRRect(rect);
    final rtl = textDirection == TextDirection.rtl;
    final barLeft = rtl ? rect.right - left.width : rect.left;
    // The bar lives inside the rounded shape; the outline starts after it.
    canvas
      ..save()
      ..clipRRect(rrect)
      ..drawRect(
        Rect.fromLTWH(barLeft, rect.top, left.width, rect.height),
        Paint()..color = left.color,
      )
      ..clipRect(
        Rect.fromLTRB(
          rtl ? rect.left : rect.left + left.width,
          rect.top,
          rtl ? barLeft : rect.right,
          rect.bottom,
        ),
      )
      ..drawRRect(
        rrect.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = top.color,
      )
      ..restore();
  }
}
