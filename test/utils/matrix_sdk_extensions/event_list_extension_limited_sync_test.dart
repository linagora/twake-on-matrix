import 'package:twake_chat/utils/matrix_sdk_extensions/event_list_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

void main() {
  late Room room;

  setUpAll(() async {
    final client = await getClient();
    room = Room(client: client, id: '!gap:example.com');
  });

  Event message(String id, int minute, {String type = EventTypes.Message}) =>
      Event(
        senderId: '@khaled:example.com',
        type: type,
        room: room,
        eventId: id,
        content: {'body': id},
        originServerTs: DateTime.utc(
          2026,
          11,
          4,
          10,
        ).add(Duration(minutes: minute)),
      );

  test('a limited sync while the room is open keeps the gap events once the '
      'history that fills it arrives', () {
    // In memory before the app is suspended: the timeline ends at Anton 10:47.
    final older = message(r'$older', 0);
    final anton = message(r'$anton', 47);
    final beforeSuspend = [anton, older];

    // Limited sync on resume: only the last events (reactions on the new
    // message), the message itself is in the gap.
    final reaction1 = message(r'$reaction1', 110, type: EventTypes.Reaction);
    final reaction2 = message(r'$reaction2', 111, type: EventTypes.Reaction);
    final afterLimitedSync = [reaction2, reaction1, anton, older];

    final firstBuild = EventListExtension.syncEventLists(
      oldEvents: beforeSuspend,
      newEvents: afterLimitedSync,
      currentTop: const [],
      currentBottom: beforeSuspend,
      wasRequestingFuture: false,
    );

    // Timeline._removeEventsNotInThisSync drops the cached events, then
    // requestHistoryOnLimitedTimeline backfills the gap, overlapping them.
    final khaled = message(r'$khaled', 105);
    final afterHistory = [reaction2, reaction1, khaled, anton, older];

    final secondBuild = EventListExtension.syncEventLists(
      oldEvents: afterLimitedSync,
      newEvents: afterHistory,
      currentTop: firstBuild.top,
      currentBottom: firstBuild.bottom,
      wasRequestingFuture: false,
    );

    expect([...secondBuild.top, ...secondBuild.bottom], contains(khaled));
  });

  test(
    'splits around the first top event kept when the bottom ones are gone',
    () {
      final shownBottom = message(r'$shownBottom', 0);
      final shownTop = message(r'$shownTop', 10);
      final between = message(r'$between', 5);
      final newer = message(r'$newer', 20);

      final result = EventListExtension.syncEventLists(
        oldEvents: [shownTop, shownBottom],
        newEvents: [newer, shownTop, between],
        currentTop: [shownTop],
        currentBottom: [shownBottom],
        wasRequestingFuture: false,
      );

      expect(result.top, [shownTop, newer]);
      expect(result.bottom, [between]);
    },
  );

  test(
    'shows the new events in the bottom list when no shown event is left',
    () {
      final shown = message(r'$shown', 0);
      final replacement = message(r'$replacement', 10);

      final result = EventListExtension.syncEventLists(
        oldEvents: [shown],
        newEvents: [replacement],
        currentTop: const [],
        currentBottom: [shown],
        wasRequestingFuture: false,
      );

      expect(result.top, isEmpty);
      expect(result.bottom, [replacement]);
    },
  );
}
