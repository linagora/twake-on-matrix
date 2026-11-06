import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/date_time_extension.dart';

/// Card under a thread root: number of messages, then author, text and age of
/// the last reply. It does not repeat the root text, which is right above.
class ThreadSummaryCard extends StatelessWidget {
  const ThreadSummaryCard({
    super.key,
    required this.replyCount,
    required this.lastReplyAuthor,
    required this.lastReplyText,
    required this.lastReplyTime,
    required this.onTap,
    this.unreadCount = 0,
  });

  final int replyCount;
  final String lastReplyAuthor;
  final String lastReplyText;
  final DateTime lastReplyTime;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    final textStyle = LinagoraTextStyle.material();
    final count = l10n.threadMessagesCount(replyCount);
    final unread = unreadCount > 0;
    final last =
        '$lastReplyAuthor: $lastReplyText · '
        '${lastReplyTime.localizedTimeShort(context)}';

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: [
        count,
        if (unread) l10n.threadUnreadMessagesCount(unreadCount),
        last,
      ].join(', '),
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: unread ? colors.primary : colors.outline,
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
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: colors.primary),
                  ],
                ),
                Text(
                  last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.bodySmall.copyWith(color: colors.secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
