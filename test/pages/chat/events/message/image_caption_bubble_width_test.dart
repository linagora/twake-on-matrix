// ignore_for_file: implementation_imports

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

class _FakeClient extends Client {
  _FakeClient()
    : super(
        'image-caption-bubble-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  @override
  String? get userID => '@alice:example.org';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final client = _FakeClient();
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
    'uses the available width for an own image caption with a short final line',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1072, 8000);
      addTearDown(tester.view.reset);

      final room = Room(id: '!room:example.org', client: client);
      final event = Event(
        content: {
          'body': '${List.filled(20, 'long-caption-without-spaces').join()}\na',
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
