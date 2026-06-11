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

    setUp(() {
      room = MockRoom();
      when(room.sendEvent(any)).thenAnswer((_) async => '\$sent:example.com');
    });

    test('sends a text event carrying the generated call_url', () {
      VideoCallHelper.start(
        room: room,
        startedTitle: 'Has started a video call',
        baseUrl: baseUrl,
      );

      final captured =
          verify(room.sendEvent(captureAny)).captured.single
              as Map<String, dynamic>;
      expect(captured['msgtype'], MessageTypes.Text);
      final url = captured[VideoCallHelper.callUrlKey] as String;
      expect(
        VideoCallHelper.extractUrl(buildTextEvent(captured), baseUrl),
        url,
      );
      expect(captured['body'], contains(url));
    });

    test('does nothing when room is null', () {
      VideoCallHelper.start(
        room: null,
        startedTitle: 'title',
        baseUrl: baseUrl,
      );
      verifyNever(room.sendEvent(any));
    });

    test('does nothing when baseUrl is null', () {
      VideoCallHelper.start(room: room, startedTitle: 'title', baseUrl: null);
      verifyNever(room.sendEvent(any));
    });
  });
}
