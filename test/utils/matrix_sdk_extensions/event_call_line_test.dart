import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/matrix_events/call_event_types.dart';
import 'package:twake_chat/domain/matrix_events/event_visibility_resolver.dart';
import 'package:twake_chat/domain/model/call/call_line.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

import '../../fake_client.dart';

void main() {
  late Room room;
  final l10n = lookupL10n(const Locale('en'));

  Event line({
    required String sender,
    int? answeredTs,
    String intent = 'audio',
  }) => Event(
    content: {
      'intent': intent,
      'started_ts': 1000,
      'answered_ts': ?answeredTs,
      'ended_ts': 66000,
      'm.relates_to': {'rel_type': 'm.reference', 'event_id': r'$ring'},
    },
    type: CallEventTypes.callLine,
    eventId: r'$line',
    senderId: sender,
    originServerTs: DateTime.fromMillisecondsSinceEpoch(66000),
    room: room,
  );

  setUpAll(() async {
    room = Room(id: '!room:example.org', client: await getClient());
  });

  test('a call nobody answered is a missed call for the others', () {
    final event = line(sender: '@alice:example.org');

    expect(event.callLine?.outcome, CallLineOutcome.missed);
    expect(event.calcLocalizedBodyFallbackRemoveBreakLine(l10n), 'Missed call');
  });

  test('a missed video call says so in the chat list', () async {
    final event = line(sender: '@alice:example.org', intent: 'video');

    expect(
      await event.calcLocalizedBodyRemoveBreakLine(l10n),
      'Missed video call',
    );
  });

  test('an answered call of someone else is an incoming call', () {
    final event = line(sender: '@alice:example.org', answeredTs: 6000);

    expect(event.callLine?.duration, const Duration(minutes: 1));
    expect(
      event.calcLocalizedBodyFallbackRemoveBreakLine(l10n),
      'Incoming call',
    );
  });

  test('a call of the user is an outgoing call', () {
    final event = line(sender: room.client.userID!);

    expect(event.callLine?.outcome, CallLineOutcome.canceled);
    expect(
      event.calcLocalizedBodyFallbackRemoveBreakLine(l10n),
      'Outgoing call',
    );
  });

  test('a call line shows in the timeline and in the chat list', () {
    final event = line(sender: '@alice:example.org');

    expect(CallEventTypes.isCallEvent(event.type), isFalse);
    expect(EventVisibilityResolver.isVisibleInTimeline(event), isTrue);
    expect(
      EventVisibilityResolver.isEligibleForChatListPreviewSync(event),
      isTrue,
    );
  });

  test('a call line without an end is not drawn', () {
    final event = Event(
      content: {'intent': 'audio'},
      type: CallEventTypes.callLine,
      eventId: r'$forged',
      senderId: '@alice:example.org',
      originServerTs: DateTime.now(),
      room: room,
    );

    expect(event.callLine, isNull);
  });
}
