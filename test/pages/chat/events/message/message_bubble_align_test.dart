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
import 'package:twake_chat/pages/chat/chat_horizontal_action_menu.dart';
import 'package:twake_chat/pages/chat/context_item_chat_action.dart';
import 'package:twake_chat/pages/chat/events/message/message_content_with_timestamp_builder.dart';
import 'package:twake_chat/utils/custom_scroll_behaviour.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/context_menu/context_menu_action_item.dart';
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
  // A phone, and a wide screen (905 px and up, ResponsiveUtils).
  const rowWidth = 390.0;
  const wideWidth = 1200.0;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton<UploadManager>(_FakeUploadManager());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Event messageFrom(String senderId, String body) => Event(
    content: {'body': body, 'msgtype': MessageTypes.Text},
    type: EventTypes.Message,
    eventId: '\$$body:example.org',
    senderId: senderId,
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
    status: EventStatus.synced,
    room: room,
  );

  // The room is a group: not a direct chat. With no member event, a sender is
  // named after its id: « Alice », « Bob ».
  final ownMessage = messageFrom('@alice:example.org', 'Hi');
  final theirMessage = messageFrom('@bob:example.org', 'Hello');

  /// [event] in a row [width] wide, the alignment stored as [align] (none
  /// stored: the default), the pointer over it when [hovered].
  Future<void> pumpMessage(
    WidgetTester tester, {
    required Event event,
    String? align,
    double width = rowWidth,
    bool hovered = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (align != null) SettingKeys.bubbleAlign: align,
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.reset);
    final isHoverNotifier = ValueNotifier<String?>(
      hovered ? event.eventId : null,
    );
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
                width: width,
                child: MessageContentWithTimestampBuilder(
                  event: event,
                  timeline: Timeline(
                    room: room,
                    chunk: TimelineChunk(events: [event]),
                  ),
                  isHoverNotifier: isHoverNotifier,
                  listHorizontalActionMenu: [
                    ContextMenuItemChatAction(
                      ChatHorizontalActionMenu.forward,
                      ContextMenuItemState.activated,
                    ),
                  ],
                  maxWidth: width,
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
    await pumpMessage(tester, event: ownMessage, align: 'left');

    expect(tester.getCenter(find.text('Hi')).dx, lessThan(rowWidth / 2));
  });

  testWidgets('« own messages on the right »: on a phone, an own message is on '
      'the right', (tester) async {
    await pumpMessage(tester, event: ownMessage, align: 'ownRight');

    expect(tester.getCenter(find.text('Hi')).dx, greaterThan(rowWidth / 2));
  });

  // Review of #3841: in a group, « every message on the left » draws my
  // messages as the others', name included; colour alone does not tell them
  // apart.
  testWidgets('« every message on the left »: on a phone, in a group, '
      'another\'s message shows its sender\'s name', (tester) async {
    await pumpMessage(tester, event: theirMessage, align: 'left');

    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('« every message on the left »: on a phone, in a group, an own '
      'message shows my name too, like the others', (tester) async {
    await pumpMessage(tester, event: ownMessage, align: 'left');

    expect(find.text('Alice'), findsOneWidget);
  });

  // The default changed for wide screens: own messages now go on the right,
  // and their hover menu on their left, towards the middle.
  testWidgets('a wide screen never asked: an own message is on the right', (
    tester,
  ) async {
    await pumpMessage(tester, event: ownMessage, width: wideWidth);

    expect(tester.getCenter(find.text('Hi')).dx, greaterThan(wideWidth / 2));
  });

  testWidgets('a wide screen never asked: the hover menu of an own message '
      'is on its left', (tester) async {
    await pumpMessage(
      tester,
      event: ownMessage,
      width: wideWidth,
      hovered: true,
    );

    expect(
      tester.getCenter(find.byIcon(Icons.shortcut)).dx,
      lessThan(tester.getTopLeft(find.text('Hi')).dx),
    );
  });

  testWidgets('a wide screen never asked: another\'s message is on the left, '
      'its hover menu on its right', (tester) async {
    await pumpMessage(
      tester,
      event: theirMessage,
      width: wideWidth,
      hovered: true,
    );

    expect(tester.getCenter(find.text('Hello')).dx, lessThan(wideWidth / 2));
    expect(
      tester.getCenter(find.byIcon(Icons.shortcut)).dx,
      greaterThan(tester.getTopRight(find.text('Hello')).dx),
    );
  });
}
