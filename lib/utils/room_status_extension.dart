import 'package:flutter/widgets.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import '../config/app_config.dart';

extension RoomStatusExtension on Room {
  CachedPresence? get directChatPresence =>
      client.presences[directChatMatrixID];

  String getLocalizedStatus(BuildContext context) {
    if (isDirectChat) {
      final directChatPresence = this.directChatPresence;
      if (directChatPresence != null) {
        if (directChatPresence.currentlyActive == true) {
          return 'online';
        }
        if (directChatPresence.lastActiveTimestamp == null) {
          return 'online long time ago';
        }
        final time = directChatPresence.lastActiveTimestamp!;

        if (DateTime.now().isAfter(time.subtract(const Duration(hours: 1)))) {
          return 'online ${DateTime.now().minute - time.minute} min ago';
        } else if (DateTime.now()
            .isAfter(time.subtract(const Duration(hours: 24)))) {
          final timeOffline = DateTime.now().difference(time);
          return 'online ${timeOffline.inHours} h ${timeOffline.inMinutes - (timeOffline.inHours * 60)} min ago';
        } else if (DateTime.now()
            .isAfter(time.subtract(const Duration(days: 7)))) {
          final timeOffline = DateTime.now().difference(time);
          return 'online ${timeOffline.inDays} day ago';
        } else if (DateTime.now()
            .isAfter(time.subtract(const Duration(days: 30)))) {
          final timeOffline = DateTime.now().difference(time);
          return 'online ${(timeOffline.inDays / 7).truncate()} week ago';
        } else if (DateTime.now()
            .isAfter(time.subtract(const Duration(days: 365)))) {
          final timeOffline = DateTime.now().difference(time);
          return 'online ${(timeOffline.inDays / 30).truncate()} month ago';
        }
        // if (directChatPresence.statusMsg?.isNotEmpty ?? false) {
        //   return directChatPresence.statusMsg!;
        // }
        // if (directChatPresence.currentlyActive == true) {
        //   return L10n.of(context)!.currentlyActive;
        // }
        // if (directChatPresence.lastActiveTimestamp == null) {
        //   return L10n.of(context)!.lastSeenLongTimeAgo;
        // }
        // return L10n.of(context)!
        //     .lastActiveAgo(time.localizedTimeShort(context));
      }
      return 'online long time ago';
    }
    return L10n.of(context)!
        .countParticipants(summary.mJoinedMemberCount.toString());
  }

  String getLocalizedTypingText(BuildContext context) {
    var typingText = '';
    final typingUsers = this.typingUsers;
    typingUsers.removeWhere((User u) => u.id == client.userID);

    if (AppConfig.hideTypingUsernames) {
      typingText = 'typing a message';
      if (typingUsers.first.id != directChatMatrixID) {
        typingText =
            L10n.of(context)!.numUsersTyping(typingUsers.length.toString());
      }
    } else if (typingUsers.length == 1) {
      typingText = 'typing a message';
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
    // now we iterate the timeline events until we hit the first rendered event
    for (final event in timeline.events) {
      lastReceipts.addAll(event.receipts.map((r) => r.user));
      if (event.eventId == eventId) {
        break;
      }
    }
    lastReceipts.removeWhere(
      (user) =>
          user.id == client.userID || user.id == timeline.events.first.senderId,
    );
    return lastReceipts.toList();
  }
}
