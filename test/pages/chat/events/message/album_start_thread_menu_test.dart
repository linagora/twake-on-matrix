// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/images_builder/media_album_scope.dart';
import 'package:twake_chat/pages/chat/events/message/message_content_with_timestamp_builder.dart';
import 'package:twake_chat/utils/custom_scroll_behaviour.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/media_album_context_extension.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/theme_builder.dart';

import '../../../../fake_client.dart';

class _FakeUploadManager implements UploadManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeClient extends Client {
  _FakeClient()
    : super(
        'album-start-thread-menu-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  @override
  String? get userID => '@alice:example.org';
}

const _screenWidth = 800.0;

/// Need (iOS report 2026-11-26): « on a message with several images, I was
/// not able to create a thread ». Reference: the web client (D89,
/// ImageAlbum.hoverActions.spec.tsx), where an album's « Start a thread »
/// starts the thread on the LAST image of the album.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final client = _FakeClient();
  final room = Room(id: '!room:example.org', client: client);

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton<UploadManager>(_FakeUploadManager());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Event image(String id, int second) => Event(
    content: {
      'msgtype': MessageTypes.Image,
      'body': '$id.png',
      'filename': '$id.png',
      'app.twake.chat.batch': 'batch-1',
    },
    type: EventTypes.Message,
    eventId: '\$$id:example.org',
    senderId: '@bob:example.org',
    originServerTs: DateTime.utc(2026, 11, 26, 10, 0, second),
    status: EventStatus.synced,
    room: room,
  );

  /// The album bubble as the room list draws it: its leader (the oldest
  /// image) under the album scope. [onStartThread] is what the room gives
  /// when a thread may be started there (null on a thread screen, or for a
  /// member who may not send).
  Future<void> pumpAlbum(
    WidgetTester tester,
    List<Event> album, {
    void Function(Event)? onStartThread,
    bool inThread = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    // Under the tablet width (905), so the long-press menu of a phone; wide
    // enough for the album grid, which is 400 px on a desktop test host.
    tester.view.physicalSize = const Size(_screenWidth, 900);
    addTearDown(tester.view.reset);

    final isHoverNotifier = ValueNotifier<String?>(null);
    addTearDown(isHoverNotifier.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: ThemeBuilder(
          builder: (context, themeMode, primaryColor) => MaterialApp(
            locale: const Locale('en'),
            scrollBehavior: CustomScrollBehavior(),
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: L10n.supportedLocales,
            theme: TwakeThemes.buildTheme(
              context,
              Brightness.light,
              primaryColor,
            ),
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomLeft,
                child: MediaAlbumScope<Event>(
                  members: album,
                  idOf: mediaAlbumEventId,
                  child: MessageContentWithTimestampBuilder(
                    event: album.first,
                    timeline: Timeline(
                      room: room,
                      chunk: TimelineChunk(events: album.reversed.toList()),
                    ),
                    isHoverNotifier: isHoverNotifier,
                    listHorizontalActionMenu: const [],
                    maxWidth: _screenWidth,
                    listActions: const [],
                    selectMode: false,
                    inThread: inThread,
                    onStartThread: onStartThread,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> longPressAlbum(WidgetTester tester) async {
    await tester.longPress(find.byType(MessageContentWithTimestampBuilder));
    await tester.pumpAndSettle();
  }

  final startThread = find.text('Start a thread');

  testWidgets('the menu of an album offers « Start a thread »', (tester) async {
    final album = [image('a', 1), image('b', 2), image('c', 3)];
    await pumpAlbum(tester, album, onStartThread: (_) {});

    await longPressAlbum(tester);

    expect(startThread, findsOneWidget);
  });

  testWidgets('« Start a thread » on an album starts it on the last image', (
    tester,
  ) async {
    final album = [image('a', 1), image('b', 2), image('c', 3)];
    final started = <Event>[];
    await pumpAlbum(tester, album, onStartThread: started.add);

    await longPressAlbum(tester);
    await tester.tap(startThread);
    await tester.pumpAndSettle();

    expect(started.map((e) => e.eventId), [album.last.eventId]);
  });

  testWidgets('no « Start a thread » on an album where none may start', (
    tester,
  ) async {
    final album = [image('a', 1), image('b', 2)];
    await pumpAlbum(tester, album);

    await longPressAlbum(tester);

    expect(find.text('Forward'), findsOneWidget);
    expect(startThread, findsNothing);
  });

  testWidgets('no « Start a thread » on an album of a thread screen', (
    tester,
  ) async {
    final album = [image('a', 1), image('b', 2)];
    await pumpAlbum(tester, album, inThread: true);

    await longPressAlbum(tester);

    expect(find.text('Forward'), findsOneWidget);
    expect(startThread, findsNothing);
  });
}
