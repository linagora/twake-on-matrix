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

/// THR-M-10 (docs/plan/2026-11-06-threads-mobile-spec.md), web D345: in the
/// list of the pinned messages of a room, « Jump to message » on a thread
/// reply opens the screen of its thread, scrolled to the reply, with the room
/// under it; on a message of the room it still opens the room on it.
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

  Future<RecordingRouter> pumpPinnedList(
    WidgetTester tester,
    List<String> pinned,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);

    fixture.room.pinned = pinned;
    final events = [
      for (final id in pinned) (await fixture.room.getEventById(id))!,
    ];
    final timeline = Timeline(
      room: fixture.room,
      chunk: TimelineChunk(events: events.reversed.toList()),
    );

    final router = RecordingRouter(
      [
        GoRoute(
          path: '/rooms/:roomid',
          builder: (_, _) => const Scaffold(body: Text('room screen')),
          routes: [
            GoRoute(
              path: 'pinnedmessages',
              builder: (_, _) =>
                  PinnedMessages(pinnedEvents: events, timeline: timeline),
            ),
            GoRoute(
              path: 'threads/:rootid',
              builder: (_, _) => const Scaffold(body: Text('thread screen')),
            ),
          ],
        ),
      ],
      initialLocation:
          '/rooms/${Uri.encodeComponent(pinsRoomId)}/pinnedmessages',
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

  /// What the item « Jump to message » of the menu of a pinned message runs.
  ///
  /// The menu itself cannot be tapped here: its items first pop the
  /// app-wide `TwakeApp.router` (popup_menu_widget_mixin.dart:25), not the
  /// router of the test. The long press is kept, to check the menu offers
  /// the item on that message.
  Future<void> jumpToMessage(WidgetTester tester, String body) async {
    await tester.longPress(pinnedText(body).first);
    await tester.pumpAndSettle();
    expect(find.text('Jump to message'), findsOneWidget);
    final list = tester.state<PinnedMessagesController>(
      find.byType(PinnedMessages),
    );
    final event = list.eventsNotifier.value.firstWhere(
      (event) => event?.body == body,
    )!;
    list.jumpToMessage(list.context, event);
    await tester.pumpAndSettle();
  }

  testWidgets('« Jump to message » on a pinned thread reply opens the screen '
      'of its thread, scrolled to the reply', (tester) async {
    final router = await pumpPinnedList(tester, [pinsReplyId]);

    await jumpToMessage(tester, 'the reply');

    expect(router.navigations, [
      'go ${const ThreadRoute(roomid: pinsRoomId, rootid: pinsRootId, event: pinsReplyId).location}',
    ]);
    expect(find.text('thread screen'), findsOneWidget);
  });

  testWidgets('« Jump to message » on a pinned message of the room still '
      'opens the room on it', (tester) async {
    final router = await pumpPinnedList(tester, [pinsRoomMessageId]);

    await jumpToMessage(tester, 'a room message');

    expect(router.navigations, [
      'go ${const RoomRoute(roomid: pinsRoomId, event: pinsRoomMessageId).location}',
    ]);
    expect(find.text('room screen'), findsOneWidget);
  });
}
