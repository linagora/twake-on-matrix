// ignore_for_file: implementation_imports

import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/message/message_content_with_timestamp_builder.dart';
import 'package:twake_chat/utils/custom_scroll_behaviour.dart';
import 'package:twake_chat/utils/manager/upload_manager/models/retry_upload_result.dart';
import 'package:twake_chat/utils/manager/upload_manager/models/upload_file_info.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';

import '../../../../fake_client.dart';

class _FakeUploadManager implements UploadManager {
  final retried = <Event>[];

  @override
  Future<RetryUploadResult> retryUpload(Event event) async {
    retried.add(event);
    return RetryUploadResult.started;
  }

  @override
  Future<UploadFileInfo?> getUploadFileInfo(
    String eventId, {
    required Room room,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeClient extends Client {
  _FakeClient()
    : super(
        'failed-message-context-menu-test',
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
  late _FakeUploadManager uploadManager;

  setUp(() {
    uploadManager = _FakeUploadManager();
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton<UploadManager>(uploadManager);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Event failedEvent(Map<String, Object?> content) => Event(
    content: content,
    type: EventTypes.Message,
    eventId: 'txid-failed',
    senderId: '@alice:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
    status: EventStatus.error,
    room: room,
  );

  Future<void> pumpBubble(WidgetTester tester, Event event) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
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
                alignment: Alignment.bottomRight,
                child: MessageContentWithTimestampBuilder(
                  event: event,
                  timeline: Timeline(
                    room: room,
                    chunk: TimelineChunk(events: [event]),
                  ),
                  isHoverNotifier: isHoverNotifier,
                  listHorizontalActionMenu: const [],
                  maxWidth: 400,
                  listActions: const [],
                  selectMode: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('long press on a failed video offers to send it again', (
    tester,
  ) async {
    final event = failedEvent({
      'body': 'video.mp4',
      'filename': 'video.mp4',
      'info': {'h': 720, 'mimetype': 'video/mp4', 'size': 1000, 'w': 1280},
      'msgtype': MessageTypes.Video,
    });
    await pumpBubble(tester, event);
    await tester.longPress(find.byType(MessageContentWithTimestampBuilder));
    await tester.pumpAndSettle();

    expect(find.text('Try to send again'), findsOneWidget);

    await tester.tap(find.text('Try to send again'));
    await tester.pumpAndSettle();

    expect(uploadManager.retried, [event]);
  });

  testWidgets('long press on a failed text message does not offer it', (
    tester,
  ) async {
    final event = failedEvent({'body': 'Hello', 'msgtype': MessageTypes.Text});

    await pumpBubble(tester, event);
    await tester.longPress(find.byType(MessageContentWithTimestampBuilder));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Try to send again'), findsNothing);
  });
}
