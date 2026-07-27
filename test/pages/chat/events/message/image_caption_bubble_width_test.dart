// ignore_for_file: implementation_imports

import 'dart:convert';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/events/message/message_content_with_timestamp_builder.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/utils/custom_scroll_behaviour.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';

import '../../../../fake_client.dart';

class _FakeUploadManager implements UploadManager {
  MatrixFile? matrixFile;

  @override
  Future<MatrixFile?> getMatrixFile(
    String eventId, {
    required Room room,
  }) async => matrixFile;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final client = Client(
    'image-caption-bubble-test',
    httpClient: FakeMatrixApi(),
    database: MockDatabase(),
  );
  late _FakeUploadManager uploadManager;

  setUp(() {
    uploadManager = _FakeUploadManager();
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton<UploadManager>(uploadManager);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'uses the available message width for a narrow image with a long caption',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1072, 900);
      addTearDown(tester.view.reset);

      final room = Room(id: '!room:example.org', client: client);
      final event = Event(
        content: {
          'body':
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
              'Aenean commodo ligula eget dolor. Aenean massa. Cum sociis '
              'natoque penatibus et magnis dis parturient montes, nascetur '
              'ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu.',
          'filename': 'portrait.png',
          'info': {'h': 1600, 'mimetype': 'image/png', 'size': 68, 'w': 400},
          'msgtype': 'm.image',
          'url': 'mxc://example.org/portrait',
        },
        type: EventTypes.Message,
        eventId: r'$portrait:example.org',
        senderId: '@alice:example.org',
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
        room: room,
      );
      uploadManager.matrixFile = MatrixImageFile(
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
        name: 'portrait.png',
        mimeType: 'image/png',
        width: 400,
        height: 1600,
      );
      final timeline = Timeline(
        room: room,
        chunk: TimelineChunk(events: [event]),
      );
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
                  alignment: Alignment.topLeft,
                  child: MessageContentWithTimestampBuilder(
                    event: event,
                    timeline: timeline,
                    isHoverNotifier: isHoverNotifier,
                    listHorizontalActionMenu: const [],
                    maxWidth: 1072,
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

      expect(tester.takeException(), isNull);
      expect(find.byType(MessageBubble), findsOneWidget);
      expect(
        tester.getSize(find.byType(MessageBubble)).width,
        MessageStyle.messageBubbleDesktopMaxWidth -
            MessageStyle.iconContextMenuSize,
      );
    },
  );
}
