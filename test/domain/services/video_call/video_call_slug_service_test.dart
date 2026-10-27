import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:twake_chat/domain/services/video_call/video_call_slug_service.dart';
import 'package:twake_chat/utils/voip/video_call_helper.dart';

import 'video_call_slug_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Room>()])
void main() {
  late VideoCallSlugService slugService;

  const baseUrl = 'https://meet.example.com';

  Event buildTextEvent(Map<String, dynamic> content) => Event(
    content: content,
    type: EventTypes.Message,
    eventId: '\$evt:example.com',
    senderId: '@alice:example.com',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(0),
    room: MockRoom(),
  );

  setUp(() {
    slugService = VideoCallSlugService();
  });

  group('VideoCallSlugService.generate', () {
    test('generate_always_returnsASlugAcceptedByExtractUrl', () {
      // Arrange
      final url = '$baseUrl/${slugService.generate()}';
      final event = buildTextEvent({
        'msgtype': MessageTypes.Text,
        'body': 'Has started a video call $url',
        VideoCallHelper.callUrlKey: url,
      });

      // Act
      final extracted = VideoCallHelper.extractUrl(event, baseUrl);

      // Assert
      expect(extracted, equals(url));
    });
  });

  group('VideoCallSlugService.parse', () {
    for (final (name, roomUrl) in [
      ('IsOneSlugUnderTheBaseUrl', '$baseUrl/abc-defg-hij'),
      ('HasATrailingSlash', '$baseUrl/abc-defg-hij/'),
      ('HasAQueryAndFragment', '$baseUrl/abc-defg-hij?lang=fr#top'),
      ('DiffersOnlyByCase', 'HTTPS://Meet.Example.com/abc-defg-hij'),
      ('HasTheDefaultPort', 'https://meet.example.com:443/abc-defg-hij'),
    ]) {
      test('parse_whenUrl${name}_returnsTheSlug', () {
        // Act
        final slug = slugService.parse(roomUrl, baseUrl: baseUrl);

        // Assert
        expect(slug, 'abc-defg-hij');
      });
    }

    test('parse_whenBaseUrlHasAPath_returnsTheSlugUnderIt', () {
      // Act
      final slug = slugService.parse(
        'https://example.com/meet/abc-defg-hij',
        baseUrl: 'https://example.com/meet',
      );

      // Assert
      expect(slug, 'abc-defg-hij');
    });

    for (final (name, roomUrl) in [
      ('IsOnAnotherHost', 'https://other.example.com/abc-defg-hij'),
      ('ExtendsTheBaseHost', 'https://meet.example.com.evil.com/abc-defg-hij'),
      ('UsesAnotherScheme', 'http://meet.example.com/abc-defg-hij'),
      ('UsesAnotherPort', 'https://meet.example.com:8443/abc-defg-hij'),
      ('HasAnExtraSegment', '$baseUrl/other/abc-defg-hij'),
      ('HasAMalformedSlug', '$baseUrl/ABC-defg-hij'),
      ('HasAShortSlug', '$baseUrl/abc-defg'),
      ('HasAUuid', '$baseUrl/6f1c2d3e-0000-4000-8000-000000000000'),
      ('IsTheBaseUrl', baseUrl),
      ('IsTheBaseUrlWithASlash', '$baseUrl/'),
      ('IsEmpty', ''),
    ]) {
      test('parse_whenUrl${name}_returnsNull', () {
        // Act
        final slug = slugService.parse(roomUrl, baseUrl: baseUrl);

        // Assert
        expect(slug, isNull);
      });
    }
  });
}
