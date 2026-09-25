import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/date_time_extension.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

import '../config/app_config.dart';

extension RoomStatusExtension on Room {
  CachedPresence? get directChatPresence =>
      client.presences[directChatMatrixID];

  String getLocalizedStatus(BuildContext context, {CachedPresence? presence}) {
    if (isDirectChat) {
      return getLocalizedStatusDirectChat(presence, context);
    }

    return _getLocalizedStatusGroupChat(context);
  }

  String getLocalizedTypingText(L10n l10n) {
    var typingText = '';
    final typingUsers = this.typingUsers;
    final ignoredUsers = client.ignoredUsers;
    typingUsers.removeWhere(
      (User u) => u.id == client.userID || ignoredUsers.contains(u.id),
    );

    if (typingUsers.isEmpty) return '';

    if (AppConfig.hideTypingUsernames) {
      typingText = l10n.isTyping;
      if (typingUsers.first.id != directChatMatrixID) {
        typingText = l10n.numUsersTyping(typingUsers.length.toString());
      }
    } else if (typingUsers.length == 1) {
      typingText = l10n.isTyping;
      if (typingUsers.first.id != directChatMatrixID) {
        typingText = l10n.userIsTyping(typingUsers.first.calcDisplayname());
      }
    } else if (typingUsers.length == 2) {
      typingText = l10n.userAndUserAreTyping(
        typingUsers.first.calcDisplayname(),
        typingUsers[1].calcDisplayname(),
      );
    } else if (typingUsers.length > 2) {
      typingText = l10n.userAndOthersAreTyping(
        typingUsers.first.calcDisplayname(),
        (typingUsers.length - 1).toString(),
      );
    }
    return typingText;
  }

  /// Other users who have read [eventId], the latest event by default.
  List<User> getSeenByUsers(Timeline timeline, {String? eventId}) {
    if (timeline.events.isEmpty) return [];
    eventId ??= timeline.events.first.eventId;
    final eventIds = timeline.events.map((e) => e.eventId).toList();
    return _seenByUsers(eventIds, eventId);
  }

  /// [getSeenByUsers] for the chat list, where no [Timeline] is loaded.
  Future<List<User>> getSeenByUsersFromStore(Event event) async {
    var eventIds = const <String>[];
    try {
      eventIds = await client.database.getEventIdList(this);
    } catch (e) {
      Logs().w('Room::getSeenByUsersFromStore: room: $id error - $e');
    }
    return _seenByUsers(eventIds, event.eventId);
  }

  /// Other users whose read receipt is on [eventId] or on a newer event.
  /// [eventIds] is ordered newest first; when it doesn't contain [eventId],
  /// only receipts on [eventId] itself count.
  List<User> _seenByUsers(List<String> eventIds, String eventId) {
    final index = eventIds.indexOf(eventId);
    final seenEventIds = {eventId, ...eventIds.take(index + 1)};
    final receipts = [
      ...receiptState.global.otherUsers.entries,
      ...?receiptState.mainThread?.otherUsers.entries,
    ];
    return receipts
        .where((receipt) => seenEventIds.contains(receipt.value.eventId))
        .map((receipt) => unsafeGetUserFromMemoryOrFallback(receipt.key))
        .toSet()
        .toList();
  }

  bool isTypingText(BuildContext context) {
    return getLocalizedTypingText(L10n.of(context)!).isNotEmpty &&
        lastEvent?.senderId == client.userID &&
        lastEvent!.status.isSending;
  }

  String _getLocalizedStatusGroupChat(BuildContext context) {
    final totalMembers =
        (summary.mInvitedMemberCount ?? 0) + (summary.mJoinedMemberCount ?? 0);

    return L10n.of(context)!.countMembers(totalMembers);
  }

  String getLocalizedStatusDirectChat(
    CachedPresence? directChatPresence,
    BuildContext context,
  ) {
    if (directChatPresence != null) {
      if (directChatPresence.presence == PresenceType.online) {
        return L10n.of(context)!.online;
      }
      final lastActiveDateTime = directChatPresence.lastActiveTimestamp;
      final currentDateTime = DateTime.now();
      if (lastActiveDateTime != null) {
        if (lastActiveDateTime.isLessThanOneMinuteAgo()) {
          return L10n.of(context)!.online;
        } else if (lastActiveDateTime.isLessThanOneHourAgo()) {
          return L10n.of(context)!.onlineMinAgo(
            currentDateTime.difference(lastActiveDateTime).inMinutes,
          );
        } else if (lastActiveDateTime.isLessThanADayAgo()) {
          final timeOffline = currentDateTime.difference(lastActiveDateTime);
          return L10n.of(
            context,
          )!.onlineHourAgo((timeOffline.inMinutes / 60).round());
        } else if (lastActiveDateTime.isLessThan30DaysAgo()) {
          return L10n.of(context)!.onlineDayAgo(
            currentDateTime.difference(lastActiveDateTime).inDays,
          );
        } else {
          return L10n.of(context)!.aWhileAgo;
        }
      }
    }
    return L10n.of(context)!.offline;
  }
}
