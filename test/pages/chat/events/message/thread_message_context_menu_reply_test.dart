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

const _me = '@alice:example.org';

class _FakeUploadManager implements UploadManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeClient extends Client {
  _FakeClient()
    : super(
        'thread-message-context-menu-reply-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  @override
  String? get userID => _me;
}

/// Clément, 2026-11-26: on the thread screen of the mobile app, the
/// long-press menu of a message offers "Reply" (quote reply), first, as in a
/// room, when the user may send messages.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Room room;

  setUp(() {
    room = Room(id: '!room:example.org', client: _FakeClient());
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton<UploadManager>(_FakeUploadManager());
  });

  tearDown(() async {
    await getIt.reset();
  });

  /// A reply of a thread, from someone else.
  Event threadReply() => Event(
    content: {
      'body': 'Hi',
      'msgtype': MessageTypes.Text,
      'm.relates_to': {
        'rel_type': RelationshipTypes.thread,
        'event_id': r'$root:example.org',
        'is_falling_back': true,
        'm.in_reply_to': {'event_id': r'$root:example.org'},
      },
    },
    type: EventTypes.Message,
    eventId: r'$reply:example.org',
    senderId: '@bob:example.org',
    originServerTs: DateTime.utc(2026, 11, 26, 10),
    status: EventStatus.synced,
    room: room,
  );

  /// The room lets only moderators send messages; the user is not one.
  void forbidSending() => room.setState(
    StrippedStateEvent(
      type: EventTypes.RoomPowerLevels,
      senderId: '@admin:example.org',
      stateKey: '',
      content: {
        'events_default': 50,
        'users_default': 0,
        'users': {_me: 0},
      },
    ),
  );

  /// The bubble of [event] on a phone; [inThread]: on the thread screen.
  /// Returns the messages "Reply" was asked for.
  Future<List<Event>> pumpBubble(
    WidgetTester tester,
    Event event, {
    required bool inThread,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);

    final isHoverNotifier = ValueNotifier<String?>(null);
    addTearDown(isHoverNotifier.dispose);
    final replied = <Event>[];

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
                  inThread: inThread,
                  onReply: replied.add,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return replied;
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.longPress(find.byType(MessageContentWithTimestampBuilder));
    await tester.pumpAndSettle();
    expect(find.text('Forward'), findsOneWidget, reason: 'the menu is open');
  }

  for (final inThread in [true, false]) {
    final where = inThread ? 'on the thread screen' : 'in the room';

    testWidgets('the long-press menu of a message $where lists "Reply" '
        'first', (tester) async {
      await pumpBubble(tester, threadReply(), inThread: inThread);

      await openMenu(tester);

      expect(find.text('Reply'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Reply')).dy,
        lessThan(tester.getTopLeft(find.text('Forward')).dy),
        reason: '"Reply" is the first action, above "Forward"',
      );
    });

    testWidgets('"Reply" in the menu of a message $where starts a reply to '
        'that message', (tester) async {
      final event = threadReply();
      final replied = await pumpBubble(tester, event, inThread: inThread);

      await openMenu(tester);
      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();

      expect(replied, [event]);
    });

    testWidgets('the menu of a message $where has no "Reply" for a member '
        'who may not send messages', (tester) async {
      forbidSending();
      await pumpBubble(tester, threadReply(), inThread: inThread);

      await openMenu(tester);

      expect(find.text('Reply'), findsNothing);
    });
  }
}
