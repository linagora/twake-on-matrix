import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fluffychat/data/cache/http_304_validator.dart';
import 'package:fluffychat/data/cache/model/cache_metadata.dart';

void main() {
  group('Http304Validator', () {
    test('schedules revalidation without blocking', () async {
      final validator = Http304Validator(
        httpClient: MockClient((request) async {
          return http.Response('', 304);
        }),
      );

      final metadata = CacheMetadata(
        etag: '"abc123"',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      // This should not block
      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/test',
        httpUri: Uri.parse('https://example.com/media/test'),
        metadata: metadata,
      );

      // Wait for background processing
      await Future.delayed(const Duration(milliseconds: 200));

      validator.dispose();
    });

    test('calls onCacheUpdated when 200 received', () async {
      var updateCalled = false;
      String? updatedUrl;
      Uint8List? updatedBytes;

      final validator = Http304Validator(
        httpClient: MockClient((request) async {
          return http.Response('new content', 200);
        }),
      );

      validator.onCacheUpdated = (url, bytes) {
        updateCalled = true;
        updatedUrl = url;
        updatedBytes = bytes;
      };

      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/test',
        httpUri: Uri.parse('https://example.com/media/test'),
        metadata: CacheMetadata(etag: '"old"', createdAt: DateTime.now()),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      expect(updateCalled, isTrue);
      expect(updatedUrl, equals('mxc://example.com/test'));
      expect(updatedBytes, isNotNull);

      validator.dispose();
    });

    test('does not call onCacheUpdated when 304 received', () async {
      var updateCalled = false;

      final validator = Http304Validator(
        httpClient: MockClient((request) async {
          return http.Response('', 304);
        }),
      );

      validator.onCacheUpdated = (url, bytes) {
        updateCalled = true;
      };

      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/test',
        httpUri: Uri.parse('https://example.com/media/test'),
        metadata: CacheMetadata(etag: '"current"', createdAt: DateTime.now()),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      expect(updateCalled, isFalse);

      validator.dispose();
    });

    test('needsRevalidation returns true when stale', () {
      final validator = Http304Validator();

      final freshMetadata = CacheMetadata(createdAt: DateTime.now());
      final staleMetadata = CacheMetadata(
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      expect(
        validator.needsRevalidation(freshMetadata, const Duration(hours: 1)),
        isFalse,
      );
      expect(
        validator.needsRevalidation(staleMetadata, const Duration(hours: 1)),
        isTrue,
      );

      validator.dispose();
    });

    test('sends If-None-Match header when etag present', () async {
      String? sentEtag;

      final validator = Http304Validator(
        httpClient: MockClient((request) async {
          sentEtag = request.headers['If-None-Match'];
          return http.Response('', 304);
        }),
      );

      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/test',
        httpUri: Uri.parse('https://example.com/media/test'),
        metadata: CacheMetadata(etag: '"abc123"', createdAt: DateTime.now()),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      expect(sentEtag, equals('"abc123"'));

      validator.dispose();
    });

    test('sends If-Modified-Since header when lastModified present', () async {
      String? sentLastModified;

      final validator = Http304Validator(
        httpClient: MockClient((request) async {
          sentLastModified = request.headers['If-Modified-Since'];
          return http.Response('', 304);
        }),
      );

      const lastModified = 'Wed, 21 Oct 2025 07:28:00 GMT';

      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/test',
        httpUri: Uri.parse('https://example.com/media/test'),
        metadata: CacheMetadata(
          lastModified: lastModified,
          createdAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      expect(sentLastModified, equals(lastModified));

      validator.dispose();
    });

    test('handles network errors gracefully', () async {
      final validator = Http304Validator(
        httpClient: MockClient((request) async {
          throw Exception('Network error');
        }),
      );

      validator.onCacheUpdated = (url, bytes) {
        fail('Should not be called on error');
      };

      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/test',
        httpUri: Uri.parse('https://example.com/media/test'),
        metadata: CacheMetadata(etag: '"abc"', createdAt: DateTime.now()),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      // Should not crash
      validator.dispose();
    });

    test('does not revalidate same URL twice concurrently', () async {
      int requestCount = 0;

      final validator = Http304Validator(
        httpClient: MockClient((request) async {
          requestCount++;
          await Future.delayed(const Duration(milliseconds: 100));
          return http.Response('', 304);
        }),
      );

      final metadata = CacheMetadata(etag: '"abc"', createdAt: DateTime.now());

      // Schedule twice quickly
      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/test',
        httpUri: Uri.parse('https://example.com/media/test'),
        metadata: metadata,
      );
      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/test',
        httpUri: Uri.parse('https://example.com/media/test'),
        metadata: metadata,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      // Should only make one request
      expect(requestCount, equals(1));

      validator.dispose();
    });

    test('processes multiple different URLs', () async {
      final processedUrls = <String>[];

      final validator = Http304Validator(
        httpClient: MockClient((request) async {
          processedUrls.add(request.url.toString());
          return http.Response('', 304);
        }),
      );

      final metadata = CacheMetadata(etag: '"abc"', createdAt: DateTime.now());

      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/a',
        httpUri: Uri.parse('https://example.com/media/a'),
        metadata: metadata,
      );
      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/b',
        httpUri: Uri.parse('https://example.com/media/b'),
        metadata: metadata,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      expect(processedUrls.length, equals(2));
      expect(processedUrls, contains('https://example.com/media/a'));
      expect(processedUrls, contains('https://example.com/media/b'));

      validator.dispose();
    });

    test('respects timeout on requests', () async {
      final validator = Http304Validator(
        httpClient: MockClient((request) async {
          // Simulate slow response
          await Future.delayed(const Duration(seconds: 10));
          return http.Response('', 200);
        }),
      );

      var callbackCalled = false;
      validator.onCacheUpdated = (url, bytes) {
        callbackCalled = true;
      };

      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/slow',
        httpUri: Uri.parse('https://example.com/media/slow'),
        metadata: CacheMetadata(etag: '"abc"', createdAt: DateTime.now()),
      );

      await Future.delayed(const Duration(seconds: 6));

      // Should have timed out and not called callback
      expect(callbackCalled, isFalse);

      validator.dispose();
    });

    test('dispose clears queue and in-progress tasks', () {
      final validator = Http304Validator();

      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/test',
        httpUri: Uri.parse('https://example.com/media/test'),
        metadata: CacheMetadata(etag: '"abc"', createdAt: DateTime.now()),
      );

      validator.dispose();

      // After dispose, scheduling should not cause any issues
      validator.scheduleRevalidation(
        mxcUrl: 'mxc://example.com/test2',
        httpUri: Uri.parse('https://example.com/media/test2'),
        metadata: CacheMetadata(etag: '"def"', createdAt: DateTime.now()),
      );
    });
  });
}
