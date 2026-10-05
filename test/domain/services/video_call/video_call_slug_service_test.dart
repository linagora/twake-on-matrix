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
    test('parse_whenUrlEndsWithASlug_returnsIt', () {
      // Act
      final slug = slugService.parse('$baseUrl/abc-defg-hij');

      // Assert
      expect(slug, 'abc-defg-hij');
    });

    test('parse_whenUrlHasATrailingSlash_ignoresIt', () {
      // Act
      final slug = slugService.parse('$baseUrl/abc-defg-hij/');

      // Assert
      expect(slug, 'abc-defg-hij');
    });

    test('parse_whenUrlIsOnAnotherHost_returnsTheSlug', () {
      // Act
      final slug = slugService.parse(
        'https://www.meet.example.org//abc-defg-hij',
      );

      // Assert
      expect(slug, 'abc-defg-hij');
    });

    test('parse_whenUrlHasAQueryString_ignoresIt', () {
      // Act
      final slug = slugService.parse('$baseUrl/abc-defg-hij?lang=fr#top');

      // Assert
      expect(slug, 'abc-defg-hij');
    });

    test('parse_always_returnsASlugAcceptedByExtractUrl', () {
      // Arrange
      final slug = slugService.parse('https://other.example.org/abc-defg-hij/');
      final event = buildTextEvent({
        'msgtype': MessageTypes.Text,
        'body': 'Has started a video call $baseUrl/$slug',
        VideoCallHelper.callUrlKey: '$baseUrl/$slug',
      });

      // Act
      final extracted = VideoCallHelper.extractUrl(event, baseUrl);

      // Assert
      expect(extracted, '$baseUrl/abc-defg-hij');
    });

    test('parse_whenSlugIsMalformed_returnsNull', () {
      // Act & Assert
      expect(slugService.parse('$baseUrl/ABC-defg-hij'), isNull);
      expect(slugService.parse('$baseUrl/abc-defg'), isNull);
      expect(
        slugService.parse('$baseUrl/6f1c2d3e-0000-4000-8000-000000000000'),
        isNull,
      );
    });

    test('parse_whenUrlHasNoSlug_returnsNull', () {
      // Act & Assert
      expect(slugService.parse(baseUrl), isNull);
      expect(slugService.parse('$baseUrl/'), isNull);
    });

    test('parse_whenUrlIsEmpty_returnsNull', () {
      // Act & Assert
      expect(slugService.parse(''), isNull);
    });
  });
}
