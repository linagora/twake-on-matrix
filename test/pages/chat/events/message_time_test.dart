import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/message_time.dart';

import '../../../fake_client.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final client = await getClient();
  final room = Room(id: '!room:example.abc', client: client);

  Event original() => Event(
    content: {'body': 'Edit me', 'msgtype': MessageTypes.Text},
    type: EventTypes.Message,
    eventId: '\$original',
    senderId: '@alice:example.abc',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    room: room,
  );

  Event edit() => Event(
    content: {
      'body': '* Edited',
      'msgtype': MessageTypes.Text,
      'm.new_content': {'body': 'Edited', 'msgtype': MessageTypes.Text},
      'm.relates_to': {
        'rel_type': RelationshipTypes.edit,
        'event_id': '\$original',
      },
    },
    type: EventTypes.Message,
    eventId: '\$edit',
    senderId: '@alice:example.abc',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1700000060000),
    room: room,
  );

  Event redaction() => Event(
    content: {},
    type: EventTypes.Redaction,
    eventId: '\$redaction',
    senderId: '@alice:example.abc',
    redacts: '\$original',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1700000120000),
    room: room,
  );

  Timeline timelineWithEdit() {
    final timeline = Timeline(
      room: room,
      chunk: TimelineChunk(events: []),
    );
    timeline.addAggregatedEvent(edit());
    return timeline;
  }

  Future<void> pumpMessageTime(
    WidgetTester tester, {
    required Event event,
    required Timeline timeline,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: MessageTime(
            event: event,
            showSeenIcon: false,
            timeline: timeline,
            timelineOverlayMessage: false,
            room: room,
          ),
        ),
      ),
    );
  }

  testWidgets('GIVEN an edited message\n'
      'THEN the edited tag is shown\n', (tester) async {
    await pumpMessageTime(
      tester,
      event: original(),
      timeline: timelineWithEdit(),
    );

    expect(find.text('edited '), findsOneWidget);
  });

  testWidgets('GIVEN an edited message that was deleted\n'
      'THEN the edited tag is hidden\n', (tester) async {
    final event = original()..setRedactionEvent(redaction());

    await pumpMessageTime(tester, event: event, timeline: timelineWithEdit());

    expect(event.redacted, isTrue);
    expect(find.text('edited '), findsNothing);
  });
}
