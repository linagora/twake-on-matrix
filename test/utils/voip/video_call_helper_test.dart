import 'package:fluffychat/utils/voip/video_call_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'video_call_helper_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Room>()])
void main() {
  const baseUrl = 'https://meet.example.com';

  Event buildTextEvent(Map<String, dynamic> content) => Event(
    content: content,
    type: EventTypes.Message,
    eventId: '\$evt:example.com',
    senderId: '@alice:example.com',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(0),
    room: MockRoom(),
  );

  group('VideoCallHelper.generateUrl', () {
    test('produces a slug matching baseUrl/xxx-xxxx-xxx', () {
      final url = VideoCallHelper.generateUrl(baseUrl);
      expect(
        RegExp(
          '^${RegExp.escape(baseUrl)}/[a-z]{3}-[a-z]{4}-[a-z]{3}\$',
        ).hasMatch(url),
        isTrue,
        reason: 'unexpected url: $url',
      );
    });

    test('round-trips: a generated url is accepted by extractUrl', () {
      final url = VideoCallHelper.generateUrl(baseUrl);
      final event = buildTextEvent({
        'msgtype': MessageTypes.Text,
        'body': 'Has started a video call $url',
        VideoCallHelper.callUrlKey: url,
      });
      expect(VideoCallHelper.extractUrl(event, baseUrl), url);
    });
  });

  group('VideoCallHelper.extractUrl', () {
    String validUrl() => '$baseUrl/abc-defg-hij';

    test('returns the url for a well-formed video call event', () {
      final event = buildTextEvent({
        'msgtype': MessageTypes.Text,
        'body': 'call',
        VideoCallHelper.callUrlKey: validUrl(),
      });
      expect(VideoCallHelper.extractUrl(event, baseUrl), validUrl());
    });

    test('returns null when baseUrl is null or empty', () {
      final event = buildTextEvent({
        'msgtype': MessageTypes.Text,
        VideoCallHelper.callUrlKey: validUrl(),
      });
      expect(VideoCallHelper.extractUrl(event, null), isNull);
      expect(VideoCallHelper.extractUrl(event, ''), isNull);
    });

    test('returns null when the call_url key is missing', () {
      final event = buildTextEvent({
        'msgtype': MessageTypes.Text,
        'body': 'plain text',
      });
      expect(VideoCallHelper.extractUrl(event, baseUrl), isNull);
    });

    test('returns null when the call_url value is an empty string', () {
      final event = buildTextEvent({
        'msgtype': MessageTypes.Text,
        VideoCallHelper.callUrlKey: '',
      });
      expect(VideoCallHelper.extractUrl(event, baseUrl), isNull);
    });

    test('returns null for a non-text message type', () {
      final event = buildTextEvent({
        'msgtype': MessageTypes.Image,
        VideoCallHelper.callUrlKey: validUrl(),
      });
      expect(VideoCallHelper.extractUrl(event, baseUrl), isNull);
    });

    test('returns null when the url does not start with baseUrl', () {
      final event = buildTextEvent({
        'msgtype': MessageTypes.Text,
        VideoCallHelper.callUrlKey: 'https://evil.example.com/abc-defg-hij',
      });
      expect(VideoCallHelper.extractUrl(event, baseUrl), isNull);
    });

    test('returns null when the slug is malformed', () {
      final event = buildTextEvent({
        'msgtype': MessageTypes.Text,
        VideoCallHelper.callUrlKey: '$baseUrl/not-a-valid-slug',
      });
      expect(VideoCallHelper.extractUrl(event, baseUrl), isNull);
    });
  });

  group('VideoCallHelper.start', () {
    late MockRoom room;

    StrippedStateEvent widgetState(String url, {String? creator}) =>
        StrippedStateEvent(
          type: 'im.vector.modular.widgets',
          stateKey: 'video_call_${creator ?? '@alice:example.com'}',
          senderId: creator ?? '@alice:example.com',
          content: {
            'type': 'm.video',
            'name': VideoCallHelper.widgetName,
            'url': url,
            'data': {'url': url},
          },
        );

    setUp(() {
      room = MockRoom();
      when(room.states).thenReturn({});
    });

    test('returns null when room or baseUrl is null', () {
      expect(VideoCallHelper.start(room: null, baseUrl: baseUrl), isNull);
      expect(VideoCallHelper.start(room: room, baseUrl: null), isNull);
    });

    test('returns a generated slug url and no longer sends a message', () {
      final url = VideoCallHelper.start(room: room, baseUrl: baseUrl);
      expect(url, isNotNull);
      expect(
        RegExp(
          '^${RegExp.escape(baseUrl)}/[a-z]{3}-[a-z]{4}-[a-z]{3}\$',
        ).hasMatch(url!),
        isTrue,
        reason: 'unexpected url: $url',
      );
      verifyNever(room.sendEvent(any));
    });

    test('joins the call already advertised in the room state', () {
      const ongoing = '$baseUrl/abc-defg-hij';
      when(room.states).thenReturn({
        'im.vector.modular.widgets': {
          'video_call_@alice:example.com': widgetState(ongoing),
        },
      });
      expect(VideoCallHelper.start(room: room, baseUrl: baseUrl), ongoing);
    });

    test('ongoingCallUrl ignores widgets pointing to other services', () {
      when(room.states).thenReturn({
        'im.vector.modular.widgets': {
          'etherpad_@alice:example.com': widgetState(
            'https://pad.example.com/p/notes',
          ),
        },
      });
      expect(VideoCallHelper.ongoingCallUrl(room, baseUrl), isNull);
    });
  });
}
