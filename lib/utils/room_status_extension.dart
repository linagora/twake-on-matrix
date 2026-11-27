import 'dart:math';

import 'package:twake_chat/domain/matrix_events/event_type_rules.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

import '../config/app_config.dart';

extension RoomStatusExtension on Room {
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

  /// The readers under each own message of [timeline], in one pass: a reader
  /// is under the newest own message at or before their receipt, the last one
  /// they read. Own events with no reader are absent.
  Map<String, List<User>> readersStoppedAtByEvent(Timeline timeline) {
    final events = timeline.events;
    final ownFrom = _newestOwnFrom(events);
    final indexById = {
      for (final (index, event) in events.indexed) event.eventId: index,
    };
    final readIndexByUser = _newestReadIndexByUser(indexById);
    final byEvent = <String, List<User>>{};
    for (final MapEntry(:key, :value) in readIndexByUser.entries) {
      final own = ownFrom[value];
      if (own != null) {
        (byEvent[own] ??= []).add(unsafeGetUserFromMemoryOrFallback(key));
      }
    }
    return byEvent;
  }

  /// The index in the timeline of the newest event each user has a receipt
  /// on; a receipt on an event [indexById] does not hold is left out.
  Map<String, int> _newestReadIndexByUser(Map<String, int> indexById) {
    final newest = <String, int>{};
    for (final MapEntry(:key, :value) in _receipts) {
      final index = indexById[value.eventId];
      if (index == null) continue;
      newest[key] = min(newest[key] ?? index, index);
    }
    return newest;
  }

  /// For each index of [events] (newest first), the id of the newest own
  /// message the chat draws at that index or older: an edit or a thread reply
  /// has no row.
  List<String?> _newestOwnFrom(List<Event> events) {
    String? newest;
    final ownFrom = List<String?>.filled(events.length, null);
    for (var index = events.length - 1; index >= 0; index--) {
      final event = events[index];
      if (event.senderId == client.userID &&
          event.isVisibleInGui &&
          EventTypeRules.userContentTypes.contains(event.type)) {
        newest = event.eventId;
      }
      ownFrom[index] = newest;
    }
    return ownFrom;
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

  Iterable<MapEntry<String, LatestReceiptStateData>> get _receipts => [
    ...receiptState.global.otherUsers.entries,
    ...?receiptState.mainThread?.otherUsers.entries,
  ];

  /// Other users whose read receipt is on [eventId] or on a newer event.
  /// [eventIds] is ordered newest first; when it doesn't contain [eventId],
  /// only receipts on [eventId] itself count.
  List<User> _seenByUsers(List<String> eventIds, String eventId) {
    final index = eventIds.indexOf(eventId);
    final seenEventIds = {eventId, ...eventIds.take(index + 1)};
    return _receipts
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

  String getLocalizedStatus(BuildContext context) {
    final totalMembers =
        (summary.mInvitedMemberCount ?? 0) + (summary.mJoinedMemberCount ?? 0);

    return L10n.of(context)!.countMembers(totalMembers);
  }
}
