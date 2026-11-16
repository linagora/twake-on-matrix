import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/thread/thread_resolved_mark.dart';
import 'package:twake_chat/utils/date_time_extension.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

/// One line of the Activity tab: avatar, the author in bold and what they
/// did, the time at the right; the room (with the start of the root of a
/// thread) below; the quoted message on two lines at most.
class ActivityRow extends StatelessWidget {
  const ActivityRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMarkRead,
  });

  final ActivityItem item;
  final VoidCallback onTap;

  /// Reads the room of an unread room item.
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    final textStyle = LinagoraTextStyle.material();
    final secondary = textStyle.bodySmall.copyWith(color: colors.secondary);
    final title = item.threadTitle;
    final quote = item.quote;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              mxContent: item.authorAvatarUrl,
              name: item.authorName,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: item.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' ${_verb(l10n)}'),
                            ],
                          ),
                          style: textStyle.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.time.localizedTimeOfDay(context),
                        style: secondary,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title == null
                              ? item.roomName
                              : '${item.roomName} · $title',
                          style: secondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Its own node: read apart from the row it sits in.
                      if (item.isResolved)
                        Semantics(container: true, child: const ResolvedMark()),
                    ],
                  ),
                  if (quote != null && quote.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        quote,
                        style: textStyle.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (item.kind == ActivityKind.unreadRoom)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: onMarkRead,
                        child: Text(l10n.markAsRead),
                      ),
                    ),
                ],
              ),
            ),
            if (item.unreadCount > 0) ...[
              const SizedBox(width: 8),
              _UnreadCount(count: item.unreadCount),
            ],
          ],
        ),
      ),
    );
  }

  String _verb(L10n l10n) => switch (item.kind) {
    ActivityKind.unreadRoom => l10n.activitySentMessage,
    ActivityKind.mention => l10n.activityMentionedYou,
    ActivityKind.reply => l10n.activityRepliedInThread,
    ActivityKind.reaction => l10n.activityReacted(item.emoji ?? ''),
  };
}

class _UnreadCount extends StatelessWidget {
  const _UnreadCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: scheme.onPrimary),
      ),
    );
  }
}
