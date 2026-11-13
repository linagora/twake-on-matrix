import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/room/chat_get_pinned_events_state.dart';
import 'package:twake_chat/domain/usecase/room/chat_get_pinned_events_interactor.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'pinned_bar_harness.dart';
import 'pins_fakes.dart';

/// THR-M-10 (docs/plan/2026-11-06-threads-mobile-spec.md), web D345 and
/// D438. In the bar of the room, a pinned thread reply opens the screen of
/// its thread, scrolled to the reply and highlighted; the conversation of
/// the room stays where it is. A pinned message of the room still scrolls
/// the room to it. In the bar of a thread, a tap jumps within the thread.
void main() {
  late PinsRoom room;
  final controllers = <FakePinsChatController>[];

  setUp(() {
    getIt
      ..registerFactory(() => ChatGetPinnedEventsInteractor())
      ..registerSingleton(ResponsiveUtils());
    room = roomWithThreads().room;
  });

  tearDown(() async {
    for (final controller in controllers) {
      controller.disposeFakes();
    }
    controllers.clear();
    await getIt.reset();
  });

  /// A screen whose pins are loaded: [pinned] in the order of the bar.
  FakePinsChatController screenWithPins(
    List<String> pinned, {
    String? threadRootId,
  }) {
    room.pinned = pinned;
    final controller = FakePinsChatController(room, threadRootId: threadRootId);
    controllers.add(controller);
    final events = <Event>[];
    for (final id in pinned) {
      events.add(_eventOf(room, id));
    }
    controller.pinnedEventsController
      ..getPinnedMessageNotifier.value = Right(
        ChatGetPinnedEventsSuccess(pinnedEvents: events),
      )
      ..updatePinnedMessage(events);
    return controller;
  }

  String roomLocation() => const RoomRoute(roomid: pinsRoomId).location;

  String threadLocation() =>
      const ThreadRoute(roomid: pinsRoomId, rootid: pinsRootId).location;

  group('the bar of the room', () {
    testWidgets('a pinned thread reply opens the screen of its thread, '
        'scrolled to the reply', (tester) async {
      final bar = screenWithPins([pinsReplyId]);
      final router = await pumpPinnedBar(
        tester,
        routes: pinnedBarRoutes(roomBar: bar),
        initialLocation: roomLocation(),
      );

      await tapPinnedBar(tester, bar, 'the reply');

      expect(router.navigations, [
        'go ${const ThreadRoute(roomid: pinsRoomId, rootid: pinsRootId, event: pinsReplyId).location}',
      ]);
      expect(find.text('thread screen'), findsOneWidget);
    });

    testWidgets('opening a pinned thread reply leaves the conversation of the '
        'room where it is', (tester) async {
      final bar = screenWithPins([pinsReplyId]);
      await pumpPinnedBar(
        tester,
        routes: pinnedBarRoutes(roomBar: bar),
        initialLocation: roomLocation(),
      );

      await tapPinnedBar(tester, bar, 'the reply');

      expect(bar.roomScrolls, 0);
    });

    testWidgets('a pinned message of the room still scrolls the room to it', (
      tester,
    ) async {
      final bar = screenWithPins([pinsRoomMessageId]);
      final router = await pumpPinnedBar(
        tester,
        routes: pinnedBarRoutes(roomBar: bar),
        initialLocation: roomLocation(),
      );

      await tapPinnedBar(tester, bar, 'a room message');

      expect(bar.roomScrolls, 1);
      expect(router.navigations, isEmpty);
    });

    testWidgets('a pinned thread root is a message of the room: the room '
        'scrolls to it', (tester) async {
      final bar = screenWithPins([pinsRootId]);
      final router = await pumpPinnedBar(
        tester,
        routes: pinnedBarRoutes(roomBar: bar),
        initialLocation: roomLocation(),
      );

      await tapPinnedBar(tester, bar, 'the root');

      expect(bar.roomScrolls, 1);
      expect(router.navigations, isEmpty);
    });

    testWidgets('each tap opens the pin shown, then shows the next one: a '
        'thread reply then a message of the room', (tester) async {
      // Pins sorted by time, as the interactor gives them; the bar shows the
      // newest first.
      final bar = screenWithPins([pinsReplyId, pinsRoomMessageId]);
      final router = await pumpPinnedBar(
        tester,
        routes: pinnedBarRoutes(roomBar: bar),
        initialLocation: roomLocation(),
      );
      // The newest pin is the room message (10:05), shown first.
      await tapPinnedBar(tester, bar, 'a room message');
      expect(bar.roomScrolls, 1);

      await tapPinnedBar(tester, bar, 'the reply');

      expect(router.navigations, [
        'go ${const ThreadRoute(roomid: pinsRoomId, rootid: pinsRootId, event: pinsReplyId).location}',
      ]);
      expect(bar.roomScrolls, 1);
    });
  });

  /// Flag off (`AppConfig.threadsEnabled`, test/config/threads_disabled_test
  /// .dart): a thread reply is an ordinary message of the room, as on main.
  group('threads off, the bar of the room', () {
    late bool flagBefore;

    setUp(() {
      flagBefore = AppConfig.threadsEnabled;
      AppConfig.threadsEnabled = false;
    });

    tearDown(() => AppConfig.threadsEnabled = flagBefore);

    testWidgets('a pinned thread reply scrolls the room to it, without '
        'opening a thread', (tester) async {
      final bar = screenWithPins([pinsReplyId]);
      final router = await pumpPinnedBar(
        tester,
        routes: pinnedBarRoutes(roomBar: bar),
        initialLocation: roomLocation(),
      );

      await tapPinnedBar(tester, bar, 'the reply');

      expect(bar.roomScrolls, 1);
      expect(router.navigations, isEmpty);
    });
  });

  group('the bar of a thread', () {
    testWidgets('a pinned reply scrolls the thread to it, without leaving '
        'the thread', (tester) async {
      final bar = screenWithPins([pinsReplyId], threadRootId: pinsRootId);
      final router = await pumpPinnedBar(
        tester,
        routes: pinnedBarRoutes(threadBar: bar),
        initialLocation: threadLocation(),
      );

      await tapPinnedBar(tester, bar, 'the reply');

      expect(bar.threadScrolls, [pinsReplyId]);
      expect(bar.roomScrolls, 0);
      expect(router.navigations, isEmpty);
    });

    testWidgets('the pinned root scrolls the thread to it, without leaving '
        'the thread', (tester) async {
      final bar = screenWithPins([pinsRootId], threadRootId: pinsRootId);
      final router = await pumpPinnedBar(
        tester,
        routes: pinnedBarRoutes(threadBar: bar),
        initialLocation: threadLocation(),
      );

      await tapPinnedBar(tester, bar, 'the root');

      expect(bar.threadScrolls, [pinsRootId]);
      expect(bar.roomScrolls, 0);
      expect(router.navigations, isEmpty);
    });

    testWidgets('like the bar of the room, each tap jumps to the pin shown '
        'then shows the next one', (tester) async {
      final bar = screenWithPins([
        pinsRootId,
        pinsReplyId,
      ], threadRootId: pinsRootId);
      await pumpPinnedBar(
        tester,
        routes: pinnedBarRoutes(threadBar: bar),
        initialLocation: threadLocation(),
      );

      await tapPinnedBar(tester, bar, 'the reply');
      await tapPinnedBar(tester, bar, 'the root');

      expect(bar.threadScrolls, [pinsReplyId, pinsRootId]);
      expect(bar.roomScrolls, 0);
    });
  });
}

Event _eventOf(PinsRoom room, String id) => switch (id) {
  pinsRootId => room.message(id, 'the root', minute: 1),
  pinsReplyId => room.message(
    id,
    'the reply',
    minute: 2,
    threadRootId: pinsRootId,
  ),
  pinsOtherReplyId => room.message(
    id,
    'a reply elsewhere',
    minute: 4,
    threadRootId: pinsOtherRootId,
  ),
  _ => room.message(id, 'a room message', minute: 5),
};
