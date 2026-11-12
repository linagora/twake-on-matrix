import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

/// The filters of the Activity tab; no « Saved »: the mobile has no saved
/// messages.
enum ActivityFilter {
  all,
  unread,
  mentions,
  replies;

  bool includes(ActivityKind kind) => switch (this) {
    all => true,
    unread => kind == ActivityKind.unreadRoom,
    mentions => kind == ActivityKind.mention,
    replies => kind == ActivityKind.reply,
  };

  String label(L10n l10n) => switch (this) {
    all => l10n.all,
    unread => l10n.activityUnread,
    mentions => l10n.activityMentions,
    replies => l10n.activityReplies,
  };
}
