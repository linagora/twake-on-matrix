import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/app_state/room/chat_get_pinned_events_state.dart';
import 'package:twake_chat/domain/usecase/room/chat_get_pinned_events_interactor.dart';

import '../../../pages/chat/chat_pinned_events/pins_fakes.dart';

/// Web D438 (twake-space-chat DECISION.md; `pinsOfThread`,
/// src/ui/pinnedLink.ts:14-19): the pinned bar of a thread shows the pins
/// of that thread only, its replies and its root, and hides while the thread
/// has no pin. Same pins of the room, same order as the bar of the room.
void main() {
  Future<List<Object?>> pinsOfThread(
    ({PinsClient client, PinsRoom room}) fixture,
    String threadRootId,
  ) => ChatGetPinnedEventsInteractor()
      .execute(
        roomId: pinsRoomId,
        client: fixture.client,
        threadRootId: threadRootId,
      )
      .toList();

  List<String?> pinnedIdsOf(Iterable<Object?> states) => states
      .whereType<Right>()
      .map((state) => state.value)
      .whereType<ChatGetPinnedEventsSuccess>()
      .single
      .pinnedEvents
      .map((event) => event?.eventId)
      .toList();

  test(
    'the pins of a thread are its pinned replies and its pinned root',
    () async {
      final fixture = roomWithThreads();
      fixture.room.pinned = [
        pinsRoomMessageId,
        pinsOtherReplyId,
        pinsReplyId,
        pinsRootId,
      ];

      final states = await pinsOfThread(fixture, pinsRootId);

      expect(pinnedIdsOf(states), unorderedEquals([pinsRootId, pinsReplyId]));
    },
  );

  test(
    'the pins of a thread come in the order of the bar of the room',
    () async {
      final fixture = roomWithThreads();
      fixture.room.pinned = [pinsReplyId, pinsRoomMessageId, pinsRootId];

      final roomStates = await ChatGetPinnedEventsInteractor()
          .execute(roomId: pinsRoomId, client: fixture.client)
          .toList();
      final threadStates = await pinsOfThread(fixture, pinsRootId);

      expect(
        pinnedIdsOf(threadStates),
        pinnedIdsOf(
          roomStates,
        ).where((id) => id == pinsRootId || id == pinsReplyId),
      );
    },
  );

  test('a thread without pin has none, although the room has some', () async {
    final fixture = roomWithThreads();
    fixture.room.pinned = [pinsRoomMessageId, pinsOtherReplyId];

    final states = await pinsOfThread(fixture, pinsRootId);

    expect(states.whereType<Right>(), isEmpty);
    expect(
      states.whereType<Left>().map((state) => state.value),
      contains(isA<ChatGetPinnedEventsNoResult>()),
    );
  });

  test('the reply of another thread is not a pin of this thread', () async {
    final fixture = roomWithThreads();
    fixture.room.pinned = [pinsOtherReplyId, pinsReplyId];

    final states = await pinsOfThread(fixture, pinsRootId);

    expect(pinnedIdsOf(states), [pinsReplyId]);
  });
}
