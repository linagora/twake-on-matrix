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
import 'package:twake_chat/pages/chat/events/message/message_content_with_timestamp_builder.dart';
import 'package:twake_chat/utils/custom_scroll_behaviour.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
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
        'message-row-long-press-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  @override
  String? get userID => '@alice:example.org';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final client = _FakeClient();
  final room = Room(id: '!room:example.org', client: client);
  const rowWidth = 400.0;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton<UploadManager>(_FakeUploadManager());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Event textEvent({required String senderId}) => Event(
    content: {'body': 'Hi', 'msgtype': MessageTypes.Text},
    type: EventTypes.Message,
    eventId: r'$short:example.org',
    senderId: senderId,
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
    status: EventStatus.synced,
    room: room,
  );

  Future<List<Event>> pumpRow(
    WidgetTester tester,
    Event event, {
    bool selectMode = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(rowWidth, 900);
    addTearDown(tester.view.reset);

    final isHoverNotifier = ValueNotifier<String?>(null);
    addTearDown(isHoverNotifier.dispose);
    final longPressed = <Event>[];

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
              body: Center(
                child: SizedBox(
                  width: rowWidth,
                  child: MessageContentWithTimestampBuilder(
                    event: event,
                    timeline: Timeline(
                      room: room,
                      chunk: TimelineChunk(events: [event]),
                    ),
                    isHoverNotifier: isHoverNotifier,
                    listHorizontalActionMenu: const [],
                    maxWidth: rowWidth,
                    listActions: const [],
                    selectMode: selectMode,
                    onLongPressMessage: longPressed.add,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return longPressed;
  }

  Offset rowPoint(WidgetTester tester, {required bool nearEnd}) {
    final row = tester.getRect(find.byType(MessageContentWithTimestampBuilder));
    return Offset(nearEnd ? row.right - 8 : row.left + 8, row.center.dy);
  }

  testWidgets('long press beside an incoming bubble selects the message', (
    tester,
  ) async {
    final event = textEvent(senderId: '@bob:example.org');
    final longPressed = await pumpRow(tester, event);

    await tester.longPressAt(rowPoint(tester, nearEnd: true));
    await tester.pumpAndSettle();

    expect(longPressed, [event]);
  });

  testWidgets('long press beside an outgoing bubble selects the message', (
    tester,
  ) async {
    final event = textEvent(senderId: '@alice:example.org');
    final longPressed = await pumpRow(tester, event);

    await tester.longPressAt(rowPoint(tester, nearEnd: false));
    await tester.pumpAndSettle();

    expect(longPressed, [event]);
  });

  testWidgets('long press on the bubble still selects the message once', (
    tester,
  ) async {
    final event = textEvent(senderId: '@bob:example.org');
    final longPressed = await pumpRow(tester, event);

    await tester.longPress(find.text('Hi'));
    await tester.pumpAndSettle();

    expect(longPressed, [event]);
  });

  testWidgets(
    'long press beside the bubble in select mode leaves it to the row',
    (tester) async {
      final event = textEvent(senderId: '@bob:example.org');
      final longPressed = await pumpRow(tester, event, selectMode: true);

      await tester.longPressAt(rowPoint(tester, nearEnd: true));
      await tester.pumpAndSettle();

      expect(longPressed, isEmpty);
    },
  );
}
