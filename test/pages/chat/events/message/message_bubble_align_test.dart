// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
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
        'message-bubble-align-test',
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
  // A phone.
  const rowWidth = 390.0;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton<UploadManager>(_FakeUploadManager());
  });

  tearDown(() async {
    await getIt.reset();
  });

  final ownMessage = Event(
    content: {'body': 'Hi', 'msgtype': MessageTypes.Text},
    type: EventTypes.Message,
    eventId: r'$own:example.org',
    senderId: '@alice:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
    status: EventStatus.synced,
    room: room,
  );

  /// The own message on a phone, the alignment stored as [align].
  Future<void> pumpOwnMessage(WidgetTester tester, String align) async {
    SharedPreferences.setMockInitialValues({SettingKeys.bubbleAlign: align});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(rowWidth, 900);
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
              body: SizedBox(
                width: rowWidth,
                child: MessageContentWithTimestampBuilder(
                  event: ownMessage,
                  timeline: Timeline(
                    room: room,
                    chunk: TimelineChunk(events: [ownMessage]),
                  ),
                  isHoverNotifier: isHoverNotifier,
                  listHorizontalActionMenu: const [],
                  maxWidth: rowWidth,
                  listActions: const [],
                  onLongPressMessage: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('« every message on the left »: on a phone, an own message is '
      'on the left', (tester) async {
    await pumpOwnMessage(tester, 'left');

    expect(tester.getCenter(find.text('Hi')).dx, lessThan(rowWidth / 2));
  });

  testWidgets('« own messages on the right »: on a phone, an own message is on '
      'the right', (tester) async {
    await pumpOwnMessage(tester, 'ownRight');

    expect(tester.getCenter(find.text('Hi')).dx, greaterThan(rowWidth / 2));
  });
}
