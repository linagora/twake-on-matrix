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
    this.color = Colors.white,
  });

  final int replyCount;

  /// Null when no reply is left to show: the card shows the count only.
  final String? lastReplyAuthor;
  final String? lastReplyText;
  final DateTime? lastReplyTime;
  final int unreadCount;

  /// White on the blue bubble of the user; a grey on a white bubble.
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    final textStyle = LinagoraTextStyle.material();
    final count = l10n.threadMessagesCount(replyCount);
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color,
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
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      count,
                      style: textStyle.labelLarge.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: colors.primary),
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

/// A 1 px outline with a 3 px bar on the left. A [Border] with a wider side
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
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final rrect = (borderRadius ?? BorderRadius.zero).toRRect(rect);
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = top.color,
    );
    canvas
      ..save()
      ..clipRRect(rrect)
      ..drawRect(
        Rect.fromLTWH(rect.left, rect.top, left.width, rect.height),
        Paint()..color = left.color,
      )
      ..restore();
  }
}
