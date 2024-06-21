import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import '../config/app_config.dart';

extension RoomStatusExtension on Room {
  CachedPresence? get directChatPresence =>
      client.presences[directChatMatrixID];

  Stream<CachedPresence> get directChatPresenceStream =>
      client.onlatestPresenceChanged.stream;

  String getLocalizedStatus(BuildContext context, {CachedPresence? presence}) {
    if (isDirectChat) {
      return getLocalizedStatusDirectChat(presence, context);
    }

    return _getLocalizedStatusGroupChat(context);
  }

  String getLocalizedTypingText(BuildContext context) {
    var typingText = '';
    final typingUsers = this.typingUsers;
    typingUsers.removeWhere((User u) => u.id == client.userID);

    if (AppConfig.hideTypingUsernames) {
      typingText = L10n.of(context)!.isTyping;
      if (typingUsers.first.id != directChatMatrixID) {
        typingText =
            L10n.of(context)!.numUsersTyping(typingUsers.length.toString());
      }
    } else if (typingUsers.length == 1) {
      typingText = L10n.of(context)!.isTyping;
      if (typingUsers.first.id != directChatMatrixID) {
        typingText =
            L10n.of(context)!.userIsTyping(typingUsers.first.calcDisplayname());
      }
    } else if (typingUsers.length == 2) {
      typingText = L10n.of(context)!.userAndUserAreTyping(
        typingUsers.first.calcDisplayname(),
        typingUsers[1].calcDisplayname(),
      );
    } else if (typingUsers.length > 2) {
      typingText = L10n.of(context)!.userAndOthersAreTyping(
        typingUsers.first.calcDisplayname(),
        (typingUsers.length - 1).toString(),
      );
    }
    return typingText;
  }

  List<User> getSeenByUsers(Timeline timeline, {String? eventId}) {
    if (timeline.events.isEmpty) return [];
    eventId ??= timeline.events.first.eventId;

    final lastReceipts = <User>{};

    if (receiptState.mainThread != null) {
      // receiptState contains all users and their last seen event
      // we checked users that have seen the eventId argument or older
      final mainThreadReceipts = receiptState.mainThread!.otherUsers.entries
          .where(
            (element) => element.value.eventId
                .isEventIdOlderOrSameAs(timeline, eventId!),
          )
          .map((e) => unsafeGetUserFromMemoryOrFallback(e.key))
          .toList();
      lastReceipts.addAll(mainThreadReceipts);
    } else {
      // now we iterate the timeline events until we hit the first rendered event
      for (final event in timeline.events) {
        lastReceipts.addAll(event.receipts.map((r) => r.user));
        if (event.eventId == eventId) {
          break;
        }
      }
      lastReceipts.removeWhere(
        (user) => user.id == client.userID,
      );
    }
    return lastReceipts.toList();
  }

  bool isTypingText(BuildContext context) {
    return getLocalizedTypingText(context).isNotEmpty &&
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
        return L10n.of(context)!.activeNow;
      }
      final lastActiveDateTime = directChatPresence.lastActiveTimestamp;
      final currentDateTime = DateTime.now();
      if (lastActiveDateTime != null) {
        if (lastActiveDateTime.isLessThanOneMinuteAgo()) {
          return L10n.of(context)!.activeNow;
        } else if (lastActiveDateTime.isLessThanOneHourAgo()) {
          return L10n.of(context)!.onlineMinAgo(
            currentDateTime.difference(lastActiveDateTime).inMinutes,
          );
        } else if (lastActiveDateTime.isLessThanADayAgo()) {
          final timeOffline = currentDateTime.difference(lastActiveDateTime);
          return L10n.of(context)!.onlineHourAgo(
            (timeOffline.inMinutes / 60).round(),
          );
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
