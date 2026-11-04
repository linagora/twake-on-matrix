import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports — TimelineChunk is not yet exported publicly
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:twake_chat/domain/matrix_events/call_event_types.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/message_content.dart';
import 'package:twake_chat/pages/chat/events/state_message.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

import '../../../fake_client.dart';

void main() {
  late Client client;
  late Room room;
  final sentAt = DateTime(2026, 11, 4, 14, 32);
  final en = lookupL10n(const Locale('en'));
  final fr = lookupL10n(const Locale('fr'));

  setUpAll(() async {
    client = await getClient();
    room = Room(client: client, id: '!call:example.com');
  });

  Event callThreadRoot({Map<String, Object?>? extra}) => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': MessageTypes.Text,
      'body': 'Meeting started at 09:00 PM',
      'm.mentions': {},
      CallEventTypes.callThreadKey: {},
      ...?extra,
    },
    eventId: '\$root',
    senderId: '@alice:example.com',
    originServerTs: sentAt,
    room: room,
  );

  Event legacyInvite() => Event(
    type: EventTypes.CallInvite,
    content: {'call_id': 'c', 'version': 1, 'lifetime': 60000},
    eventId: '\$invite',
    senderId: '@alice:example.com',
    originServerTs: sentAt,
    room: room,
  );

  group('call thread root', () {
    test('is marked by app.twake.chat.call_thread', () {
      expect(callThreadRoot().isCallThreadRoot, isTrue);
      expect(
        Event(
          type: EventTypes.Message,
          content: {'msgtype': MessageTypes.Text, 'body': 'hello'},
          eventId: '\$msg',
          senderId: '@alice:example.com',
          originServerTs: sentAt,
          room: room,
        ).isCallThreadRoot,
        isFalse,
      );
    });

    test('reads the time of its event, not the body sent', () {
      final time = DateFormat('HH:mm').format(sentAt);
      expect(
        callThreadRoot().callThreadRootText(en),
        'Meeting started at $time',
      );
      expect(
        callThreadRoot().callThreadRootText(fr),
        'Réunion démarrée à $time',
      );
    });

    test('chat-list preview shows the notice', () async {
      final event = callThreadRoot();
      final expected = event.callThreadRootText(en);
      expect(event.calcLocalizedBodyFallbackRemoveBreakLine(en), expected);
      expect(await event.calcLocalizedBodyRemoveBreakLine(en), expected);
    });

    testWidgets('bubble shows the notice', (tester) async {
      final event = callThreadRoot();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: MessageContent(
              event,
              videoCallBaseUrl: null,
              textColor: Colors.black,
              endOfBubbleWidget: const SizedBox.shrink(),
              ownMessage: false,
              timeline: Timeline(
                room: room,
                chunk: TimelineChunk(events: [event]),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(event.callThreadRootText(en)), findsOneWidget);
      expect(find.text('Meeting started at 09:00 PM'), findsNothing);
    });
  });

  group('legacy m.call.invite', () {
    testWidgets('shows one line, no button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(body: StateMessage(legacyInvite())),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Call from an app Twake Chat does not support'),
        findsOneWidget,
      );
      expect(find.byType(ButtonStyleButton), findsNothing);
    });
  });
}
