import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports — TimelineChunk is not yet exported publicly
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/matrix_events/call_event_types.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/call_line_bubble.dart';
import 'package:twake_chat/pages/chat/events/message/message.dart';
import 'package:twake_chat/pages/chat/sticky_timestamp_widget.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../fake_client.dart';

void main() {
  late Room room;

  setUpAll(() async {
    room = Room(id: '!room:example.org', client: await getClient());
  });

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    getIt.registerSingleton<ResponsiveUtils>(ResponsiveUtils());
  });
  tearDown(getIt.reset);

  Event callLine({required String eventId, required DateTime sentAt}) => Event(
    content: {
      'intent': 'audio',
      'started_ts': sentAt.millisecondsSinceEpoch,
      'ended_ts': sentAt.millisecondsSinceEpoch,
      'm.relates_to': {'rel_type': 'm.reference', 'event_id': r'$ring'},
    },
    type: CallEventTypes.callLine,
    eventId: eventId,
    senderId: '@alice:example.org',
    originServerTs: sentAt,
    room: room,
  );

  Future<void> pump(
    WidgetTester tester,
    Event event, {
    Event? nextEvent,
    String? markedUnreadLocation,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
      locale: const Locale('en'),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      home: Scaffold(
        body: Message(
          event,
          nextEvent: nextEvent,
          markedUnreadLocation: markedUnreadLocation,
          timeline: Timeline(
            room: room,
            chunk: TimelineChunk(events: [event]),
          ),
          isHoverNotifier: ValueNotifier(null),
          listHorizontalActionMenu: const [],
          listAction: const [],
          maxWidth: 400,
        ),
      ),
    ),
  );

  testWidgets('the first call line of a day keeps the date separator', (
    tester,
  ) async {
    await pump(
      tester,
      callLine(eventId: r'$line', sentAt: DateTime(2026, 11, 26, 14, 32)),
      nextEvent: callLine(
        eventId: r'$older',
        sentAt: DateTime(2026, 11, 25, 9),
      ),
    );

    expect(find.byType(CallLineBubble), findsOneWidget);
    expect(find.byType(StickyTimestampWidget), findsOneWidget);
  });

  testWidgets('a call line of the same day has no date separator', (
    tester,
  ) async {
    await pump(
      tester,
      callLine(eventId: r'$line', sentAt: DateTime(2026, 11, 26, 14, 32)),
      nextEvent: callLine(
        eventId: r'$older',
        sentAt: DateTime(2026, 11, 26, 9),
      ),
    );

    expect(find.byType(StickyTimestampWidget), findsNothing);
  });

  testWidgets('the first unread call line keeps the unread marker', (
    tester,
  ) async {
    final event = callLine(
      eventId: r'$line',
      sentAt: DateTime(2026, 11, 26, 14, 32),
    );
    await pump(
      tester,
      event,
      nextEvent: callLine(
        eventId: r'$older',
        sentAt: DateTime(2026, 11, 26, 9),
      ),
      markedUnreadLocation: event.eventId,
    );

    expect(find.text('Unread messages'), findsOneWidget);
  });
}
