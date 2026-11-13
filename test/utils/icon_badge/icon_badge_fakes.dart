import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/utils/icon_badge/icon_badge_updater.dart';

import '../thread_unread/thread_fakes.dart';

/// A write that took the badge off the icon.
const int? removed = null;

/// The app icon badge, recording what the app wrote on it, in order: the
/// count shown, or [removed].
class RecordedIconBadge implements IconBadge {
  final List<int?> writes = [];

  @override
  void show(int count) => writes.add(count);

  @override
  void remove() => writes.add(removed);
}

/// An account that keeps the thread counters, with the rooms and the syncs
/// the test gives it. The server says the user never wrote in any thread,
/// so a thread is followed only when the test says so, unless the test
/// makes the server [answerLater].
class BadgeAccount extends RecordingThreadClient {
  bool _slow = false;
  bool _participated = false;
  final Completer<void> _answer = Completer();

  @override
  final List<Room> rooms = [];

  @override
  final CachedStreamController<SyncUpdate> onSync = CachedStreamController();

  @override
  final CachedStreamController<LoginState> onLoginStateChanged =
      CachedStreamController();

  @override
  String? get userID => '@me:example.com';

  @override
  Future<MatrixEvent> getOneRoomEvent(String? roomId, String? eventId) async {
    if (_slow) await _answer.future;
    return MatrixEvent(
      type: EventTypes.Message,
      content: const {'msgtype': 'm.text', 'body': 'root'},
      senderId: '@bob:example.com',
      eventId: eventId!,
      originServerTs: DateTime.utc(2026, 11, 13),
      unsigned: {
        'm.relations': {
          'm.thread': {'count': 3, 'current_user_participated': _participated},
        },
      },
    );
  }

  /// The server answers whether the user wrote in a thread only once the
  /// test calls [answersUserWroteIn].
  void answerLater() => _slow = true;

  /// The late answer comes: the user wrote in [thread], so they follow it.
  Future<void> answersUserWroteIn(ThreadRef thread) async {
    _participated = true;
    _answer.complete();
    await threadUnread.followOnceKnown(thread);
    await pumpEventQueue();
  }

  /// A room of the account the user joined, nothing unread in it.
  Room joined(RoomId id) => _add(Room(id: id.value, client: this));

  /// A room the user is invited to.
  Room invitedTo(RoomId id) =>
      _add(Room(id: id.value, client: this, membership: Membership.invite));

  /// A room the user left, with the unread count it had then.
  Room left(RoomId id) =>
      _add(Room(id: id.value, client: this, membership: Membership.leave));

  Room _add(Room room) {
    rooms.add(room);
    return room;
  }

  /// The thread has [counts] unread, as the sync gave them; once the store
  /// knows whether the user follows it.
  Future<void> threadHas(ThreadRef thread, ThreadCounts counts) async {
    threadGets(thread, counts);
    await threadUnread.followOnceKnown(thread);
  }

  /// The sync gives the thread [counts]; whether the user follows it may
  /// still be looked up.
  void threadGets(ThreadRef thread, ThreadCounts counts) {
    threadUnread.apply(
      SyncThreadUpdate(
        counts: {
          thread.roomId: {thread.rootEventId: counts},
        },
        leftRoomIds: const [],
      ),
    );
  }

  /// A sync that brings news of [room], handled by the app.
  Future<void> syncs(Room room) async {
    final update = room.membership == Membership.invite
        ? RoomsUpdate(invite: {room.id: InvitedRoomUpdate()})
        : RoomsUpdate(join: {room.id: JoinedRoomUpdate()});
    onSync.add(SyncUpdate(nextBatch: 'batch', rooms: update));
    await pumpEventQueue();
  }
}

/// The system tells the app it is in the foreground.
Future<void> appInForeground() => _appIs(AppLifecycleState.resumed);

/// The system tells the app it went to the background (iOS: inactive, then
/// hidden, then paused).
Future<void> appGoesToBackground() => _appIs(AppLifecycleState.paused);

Future<void> _appIs(AppLifecycleState state) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        SystemChannels.lifecycle.name,
        SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
        (_) {},
      );
  await pumpEventQueue();
}
