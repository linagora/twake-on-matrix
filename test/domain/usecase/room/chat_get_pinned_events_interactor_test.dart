import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/app_state/room/chat_get_pinned_events_state.dart';
import 'package:twake_chat/domain/usecase/room/chat_get_pinned_events_interactor.dart';

import '../../../pages/chat/chat_pinned_events/pins_fakes.dart';

/// THR-M-10 (docs/plan/2026-11-06-threads-mobile-spec.md), web D345: a
/// message pinned from a thread shows in the pinned bar and list of the room
/// like any other. The thread reply is hidden from the main timeline, not
/// from the pins of the room.
void main() {
  List<String?> pinnedIdsOf(Iterable<Object?> states) => states
      .whereType<Right>()
      .map((state) => state.value)
      .whereType<ChatGetPinnedEventsSuccess>()
      .single
      .pinnedEvents
      .map((event) => event?.eventId)
      .toList();

  test('a pinned thread reply is one of the pins of the room', () async {
    final fixture = roomWithThreads();
    fixture.room.pinned = [pinsRoomMessageId, pinsReplyId];

    final states = await ChatGetPinnedEventsInteractor()
        .execute(roomId: pinsRoomId, client: fixture.client)
        .toList();

    expect(
      pinnedIdsOf(states),
      unorderedEquals([pinsRoomMessageId, pinsReplyId]),
    );
  });

  test('a room whose only pin is a thread reply still has a pin', () async {
    final fixture = roomWithThreads();
    fixture.room.pinned = [pinsReplyId];

    final states = await ChatGetPinnedEventsInteractor()
        .execute(roomId: pinsRoomId, client: fixture.client)
        .toList();

    expect(pinnedIdsOf(states), [pinsReplyId]);
  });
}
