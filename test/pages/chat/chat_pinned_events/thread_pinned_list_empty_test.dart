// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/room/delete_event_interactor.dart';
import 'package:twake_chat/domain/usecase/room/update_pinned_messages_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat_pinned_events/pinned_messages.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'pinned_bar_harness.dart';
import 'pins_fakes.dart';

class _FakeUploadManager implements UploadManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

/// Web D438, threads P4 (docs/plan/2026-11-06-threads-mobile-spec.md): the
/// list of the pinned messages of a thread (its bar, then the list icon)
/// holds the pins of that thread only. With no pin left, it goes back to the
/// thread it was opened from, not to the room. « Unpin all messages » there
/// unpins the pins of that thread only: the room keeps its other pins. The
/// list of the room still goes back to the room.
void main() {
  late ({PinsClient client, PinsRoom room}) fixture;

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    getIt
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton<UploadManager>(_FakeUploadManager())
      ..registerFactory(() => UpdatePinnedMessagesInteractor())
      ..registerFactory(() => DeleteEventInteractor());
    fixture = roomWithThreads();
  });

  tearDown(() async {
    await getIt.reset();
  });

  final threadLocation = const ThreadRoute(
    roomid: pinsRoomId,
    rootid: pinsRootId,
  ).location;
  final roomLocation = const RoomRoute(roomid: pinsRoomId).location;

  /// Opens the pinned list of the thread ([inThread]) or of the room, over
  /// the screens it is opened from, with [listed] as the pins it was given.
  Future<RecordingRouter> pumpPinnedList(
    WidgetTester tester, {
    required bool inThread,
    required List<String> listed,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);

    final events = [
      for (final id in listed) (await fixture.room.getEventById(id))!,
    ];
    final timeline = Timeline(
      room: fixture.room,
      chunk: TimelineChunk(events: events.reversed.toList()),
    );
    Widget list({String? threadRootId}) => PinnedMessages(
      pinnedEvents: events,
      timeline: timeline,
      threadRootId: threadRootId,
    );

    final router = RecordingRouter(
      [
        GoRoute(
          path: '/rooms/:roomid',
          builder: (_, _) => const Scaffold(body: Text('room screen')),
          routes: [
            GoRoute(path: 'pinnedmessages', builder: (_, _) => list()),
            GoRoute(
              path: 'threads/:rootid',
              builder: (_, _) => const Scaffold(body: Text('thread screen')),
              routes: [
                GoRoute(
                  path: 'pinnedmessages',
                  builder: (_, state) =>
                      list(threadRootId: state.pathParameters['rootid']),
                ),
              ],
            ),
          ],
        ),
      ],
      initialLocation:
          '${inThread ? threadLocation : roomLocation}/pinnedmessages',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: Provider<MatrixState>.value(
          value: _FakeMatrixState(fixture.client),
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: L10n.supportedLocales,
            builder: (context, child) => Theme(
              data: TwakeThemes.buildTheme(context, Brightness.light),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  /// Where the app is, decoded: go_router keeps the ids encoded after a `go`
  /// and decoded after a pop.
  String locationOf(GoRouter router) =>
      Uri.decodeFull(router.routerDelegate.currentConfiguration.uri.toString());

  String decoded(String location) => Uri.decodeFull(location);

  Finder unpinAll() => find.text('Unpin all messages');

  group('the pinned list of a thread', () {
    testWidgets('opened with no pin, it goes back to the thread', (
      tester,
    ) async {
      fixture.room.pinned = [pinsRoomMessageId];
      final router = await pumpPinnedList(tester, inThread: true, listed: []);
      // The crash of an empty list is its own spec, below.
      tester.takeException();

      expect(locationOf(router), decoded(threadLocation));
      expect(find.text('thread screen'), findsOneWidget);
    });

    testWidgets('« Unpin all messages » goes back to the thread', (
      tester,
    ) async {
      fixture.room.pinned = [
        pinsRoomMessageId,
        pinsOtherReplyId,
        pinsReplyId,
        pinsRootId,
      ];
      final router = await pumpPinnedList(
        tester,
        inThread: true,
        listed: [pinsRootId, pinsReplyId],
      );

      await tester.tap(unpinAll());
      await tester.pumpAndSettle();

      expect(locationOf(router), decoded(threadLocation));
      expect(find.text('thread screen'), findsOneWidget);
    });

    testWidgets('« Unpin all messages » unpins the pins of the thread only', (
      tester,
    ) async {
      fixture.room.pinned = [
        pinsRoomMessageId,
        pinsOtherReplyId,
        pinsReplyId,
        pinsRootId,
      ];
      await pumpPinnedList(
        tester,
        inThread: true,
        listed: [pinsRootId, pinsReplyId],
      );

      await tester.tap(unpinAll());
      await tester.pumpAndSettle();

      expect(
        fixture.room.pinned,
        unorderedEquals([pinsRoomMessageId, pinsOtherReplyId]),
      );
    });

    testWidgets('unpinning its last pin goes back to the thread', (
      tester,
    ) async {
      fixture.room.pinned = [pinsRoomMessageId, pinsReplyId];
      final router = await pumpPinnedList(
        tester,
        inThread: true,
        listed: [pinsReplyId],
      );

      // What « Unpin » of the menu of the pinned message runs: the menu
      // pops the app-wide TwakeApp.router first, absent from this test.
      tester
          .state<PinnedMessagesController>(find.byType(PinnedMessages))
          .unpin(pinsReplyId);
      await tester.pumpAndSettle();

      expect(fixture.room.pinned, [pinsRoomMessageId]);
      expect(locationOf(router), decoded(threadLocation));
      expect(find.text('thread screen'), findsOneWidget);
    });
  });

  group('the pinned list of the room', () {
    testWidgets('opened with no pin, it still goes back to the room', (
      tester,
    ) async {
      final router = await pumpPinnedList(tester, inThread: false, listed: []);
      // The crash of an empty list is its own spec, below.
      tester.takeException();

      expect(locationOf(router), decoded(roomLocation));
      expect(find.text('room screen'), findsOneWidget);
    });
  });

  group('an empty pinned list', () {
    // Found while writing the specs above: `PinnedMessagesController.room`
    // reads `pinnedEvents.first` (pinned_messages.dart:79), so the list
    // throws while it is built, before it goes back.
    for (final inThread in [true, false]) {
      testWidgets('of the ${inThread ? 'thread' : 'room'} goes back without '
          'an error', (tester) async {
        await pumpPinnedList(tester, inThread: inThread, listed: []);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('« Unpin all messages » unpins every pin of the room and goes '
        'back to the room', (tester) async {
      fixture.room.pinned = [pinsRoomMessageId, pinsReplyId];
      final router = await pumpPinnedList(
        tester,
        inThread: false,
        listed: [pinsReplyId, pinsRoomMessageId],
      );

      await tester.tap(unpinAll());
      await tester.pumpAndSettle();

      expect(fixture.room.pinned, isEmpty);
      expect(locationOf(router), decoded(roomLocation));
      expect(find.text('room screen'), findsOneWidget);
    });
  });
}
