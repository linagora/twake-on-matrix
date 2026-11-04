import 'package:twake_chat/utils/matrix_sdk_extensions/event_list_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

late Room _room;

Event _message(String id, int minute, {String type = EventTypes.Message}) =>
    Event(
      senderId: '@khaled:example.com',
      type: type,
      room: _room,
      eventId: id,
      content: {'body': id},
      originServerTs: DateTime.utc(
        2026,
        11,
        4,
        10,
      ).add(Duration(minutes: minute)),
    );

EventListSyncResult _sync({
  required List<Event> oldEvents,
  required List<Event> newEvents,
  required List<Event> currentTop,
  required List<Event> currentBottom,
}) => EventListExtension.syncEventLists(
  oldEvents: oldEvents,
  newEvents: newEvents,
  currentTop: currentTop,
  currentBottom: currentBottom,
  wasRequestingFuture: false,
);

void main() {
  setUpAll(() async {
    _room = Room(client: await getClient(), id: '!gap:example.com');
  });

  test(
    'a limited sync while the room is open keeps the gap events once the '
    'history that fills it arrives',
    _keepsGapEventsAfterLimitedSync,
  );
  test(
    'splits around the first top event kept when the bottom ones are gone',
    _splitsAroundTopAnchor,
  );
  test(
    'shows the new events in the bottom list when no shown event is left',
    _resetsWhenNoShownEventIsLeft,
  );
}

void _keepsGapEventsAfterLimitedSync() {
  // In memory before the app is suspended: the timeline ends at Anton 10:47.
  final older = _message(r'$older', 0);
  final anton = _message(r'$anton', 47);
  final beforeSuspend = [anton, older];

  // Limited sync on resume: only the last events (reactions on the new
  // message), the message itself is in the gap.
  final reaction1 = _message(r'$reaction1', 110, type: EventTypes.Reaction);
  final reaction2 = _message(r'$reaction2', 111, type: EventTypes.Reaction);
  final afterLimitedSync = [reaction2, reaction1, anton, older];

  final firstBuild = _sync(
    oldEvents: beforeSuspend,
    newEvents: afterLimitedSync,
    currentTop: const [],
    currentBottom: beforeSuspend,
  );

  // Timeline._removeEventsNotInThisSync drops the cached events, then
  // requestHistoryOnLimitedTimeline backfills the gap, overlapping them.
  final khaled = _message(r'$khaled', 105);
  final afterHistory = [reaction2, reaction1, khaled, anton, older];

  final secondBuild = _sync(
    oldEvents: afterLimitedSync,
    newEvents: afterHistory,
    currentTop: firstBuild.top,
    currentBottom: firstBuild.bottom,
  );

  expect([...secondBuild.top, ...secondBuild.bottom], contains(khaled));
}

void _splitsAroundTopAnchor() {
  final shownBottom = _message(r'$shownBottom', 0);
  final shownTop = _message(r'$shownTop', 10);
  final between = _message(r'$between', 5);
  final newer = _message(r'$newer', 20);

  final result = _sync(
    oldEvents: [shownTop, shownBottom],
    newEvents: [newer, shownTop, between],
    currentTop: [shownTop],
    currentBottom: [shownBottom],
  );

  expect(result.top, [shownTop, newer]);
  expect(result.bottom, [between]);
}

void _resetsWhenNoShownEventIsLeft() {
  final shown = _message(r'$shown', 0);
  final replacement = _message(r'$replacement', 10);

  final result = _sync(
    oldEvents: [shown],
    newEvents: [replacement],
    currentTop: const [],
    currentBottom: [shown],
  );

  expect(result.top, isEmpty);
  expect(result.bottom, [replacement]);
}
