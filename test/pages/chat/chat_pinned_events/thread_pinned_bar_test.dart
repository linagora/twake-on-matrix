import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/room/chat_get_pinned_events_interactor.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'pinned_bar_harness.dart';
import 'pins_fakes.dart';

/// Web D438 (twake-space-chat DECISION.md; src/ui/PinnedBar.tsx,
/// src/ui/pinnedLink.ts:14-19), threads P4 of
/// docs/plan/2026-11-06-threads-mobile-spec.md: under the header of the
/// thread screen, the pinned bar of the room for the pins of that thread
/// only, its replies and its root. Same cycle and live update as in a room;
/// hidden while the thread has no pin. Pinning or unpinning from the thread
/// screen updates the bar of the thread and the bar of the room.
///
/// Assumed API: the thread screen loads its pins as the room screen does,
/// with the id of its root: `PinnedEventsController.getPinnedMessageAction(
/// ..., threadRootId:)`, passed on to `ChatGetPinnedEventsInteractor.execute(
/// ..., threadRootId:)`.
void main() {
  late ({PinsClient client, PinsRoom room}) fixture;
  final screens = <FakePinsChatController>[];

  setUp(() {
    getIt
      ..registerFactory(() => ChatGetPinnedEventsInteractor())
      ..registerSingleton(ResponsiveUtils());
    fixture = roomWithThreads();
  });

  tearDown(() async {
    for (final screen in screens) {
      screen.disposeFakes();
    }
    screens.clear();
    await getIt.reset();
  });

  FakePinsChatController threadScreen() {
    final screen = FakePinsChatController(
      fixture.room,
      threadRootId: pinsRootId,
    );
    screens.add(screen);
    return screen;
  }

  FakePinsChatController roomScreen() {
    final screen = FakePinsChatController(fixture.room);
    screens.add(screen);
    return screen;
  }

  /// Loads (or reloads) the pins of [screen] as its Chat does on open
  /// ([isInitial]), after a pin ([eventId]) or after an unpin ([isUnpin]),
  /// then lets the bar settle (the controller waits 1 s before loading).
  Future<void> load(
    WidgetTester tester,
    FakePinsChatController screen, {
    bool isInitial = false,
    bool isUnpin = false,
    String? eventId,
  }) async {
    screen.pinnedEventsController.getPinnedMessageAction(
      roomId: pinsRoomId,
      client: fixture.client,
      isInitial: isInitial,
      isUnpin: isUnpin,
      eventId: eventId,
      threadRootId: screen.threadRootId,
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Future<void> pumpThreadScreen(
    WidgetTester tester,
    FakePinsChatController thread, {
    FakePinsChatController? room,
  }) => pumpPinnedBar(
    tester,
    routes: pinnedBarRoutes(roomBar: room, threadBar: thread),
    initialLocation: const ThreadRoute(
      roomid: pinsRoomId,
      rootid: pinsRootId,
    ).location,
  );

  Finder listButton() => find.byTooltip('Pinned messages');

  testWidgets('the bar of a thread shows its pinned reply and its pinned '
      'root, one after the other', (tester) async {
    fixture.room.pinned = [
      pinsRoomMessageId,
      pinsOtherReplyId,
      pinsReplyId,
      pinsRootId,
    ];
    final thread = threadScreen();
    await pumpThreadScreen(tester, thread);
    await load(tester, thread, isInitial: true);

    // The newest pin of the thread first, as in the bar of the room.
    expect(pinnedText('the reply'), findsOneWidget);
    await tapPinnedBar(tester, thread, 'the reply');
    expect(pinnedText('the root'), findsOneWidget);
    await tapPinnedBar(tester, thread, 'the root');
    expect(pinnedText('the reply'), findsOneWidget);
  });

  testWidgets('the bar of a thread never shows a pin of the room or of '
      'another thread', (tester) async {
    fixture.room.pinned = [
      pinsRoomMessageId,
      pinsOtherReplyId,
      pinsReplyId,
      pinsRootId,
    ];
    final thread = threadScreen();
    await pumpThreadScreen(tester, thread);
    await load(tester, thread, isInitial: true);

    for (var i = 0; i < 3; i++) {
      expect(pinnedText('a room message'), findsNothing);
      expect(pinnedText('a reply elsewhere'), findsNothing);
      final shown = pinnedText('the reply').evaluate().isNotEmpty
          ? 'the reply'
          : 'the root';
      await tapPinnedBar(tester, thread, shown);
    }
  });

  testWidgets('a thread without pin shows no bar, although the room has '
      'pins', (tester) async {
    fixture.room.pinned = [pinsRoomMessageId, pinsOtherReplyId];
    final thread = threadScreen();
    await pumpThreadScreen(tester, thread);
    await load(tester, thread, isInitial: true);

    expect(pinnedText('a room message'), findsNothing);
    expect(pinnedText('a reply elsewhere'), findsNothing);
    expect(listButton(), findsNothing);
  });

  testWidgets('a reply pinned from the thread screen shows in the bar of the '
      'thread', (tester) async {
    fixture.room.pinned = [pinsRoomMessageId];
    final thread = threadScreen();
    await pumpThreadScreen(tester, thread);
    await load(tester, thread, isInitial: true);
    expect(listButton(), findsNothing);

    fixture.room.pinned = [pinsRoomMessageId, pinsReplyId];
    await load(tester, thread, eventId: pinsReplyId);

    expect(pinnedText('the reply'), findsOneWidget);
    expect(pinnedText('a room message'), findsNothing);
  });

  testWidgets('a reply pinned from the thread screen shows in the bar of the '
      'room under it', (tester) async {
    fixture.room.pinned = [pinsRoomMessageId];
    final thread = threadScreen();
    final room = roomScreen();
    await pumpThreadScreen(tester, thread, room: room);
    await load(tester, room, isInitial: true);
    await load(tester, thread, isInitial: true);

    fixture.room.pinned = [pinsRoomMessageId, pinsReplyId];
    // The room screen hears the change of `m.room.pinned_events` and
    // reloads; the pin lands on the reply.
    await load(tester, room, eventId: pinsReplyId);
    await load(tester, thread, eventId: pinsReplyId);

    // Both bars: the room one (offstage, under the thread) and the thread one.
    expect(
      find.textContaining('the reply', findRichText: true, skipOffstage: false),
      findsNWidgets(2),
    );
  });

  testWidgets('unpinning the last pin of a thread hides the bar of the '
      'thread', (tester) async {
    fixture.room.pinned = [pinsRoomMessageId, pinsReplyId];
    final thread = threadScreen();
    await pumpThreadScreen(tester, thread);
    await load(tester, thread, isInitial: true);
    expect(pinnedText('the reply'), findsOneWidget);

    fixture.room.pinned = [pinsRoomMessageId];
    await load(tester, thread, isUnpin: true);

    expect(pinnedText('the reply'), findsNothing);
    expect(pinnedText('a room message'), findsNothing);
    expect(listButton(), findsNothing);
  });

  testWidgets('unpinning a reply from the thread screen takes it off the bar '
      'of the room', (tester) async {
    fixture.room.pinned = [pinsRoomMessageId, pinsReplyId];
    final thread = threadScreen();
    final room = roomScreen();
    await pumpThreadScreen(tester, thread, room: room);
    await load(tester, room, isInitial: true);
    await load(tester, thread, isInitial: true);

    fixture.room.pinned = [pinsRoomMessageId];
    await load(tester, room, isUnpin: true);
    await load(tester, thread, isUnpin: true);

    expect(
      find.textContaining('the reply', findRichText: true, skipOffstage: false),
      findsNothing,
    );
    expect(
      find.textContaining(
        'a room message',
        findRichText: true,
        skipOffstage: false,
      ),
      findsOneWidget,
      reason: 'The bar of the room keeps its other pin',
    );
  });
}
