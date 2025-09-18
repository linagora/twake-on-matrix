import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/data/memory/mxc_image_cache_manager.dart';

void main() {
  group('MxcImageCacheManager', () {
    late MxcImageCacheManager manager;

    setUp(() {
      manager = MxcImageCacheManager.instance;
    });

    tearDown(() {
      // Clear the cache after each test
      // We can't directly access the private _imageCache, so we'll add a large number of items to force eviction
      for (int i = 0; i < 100; i++) {
        manager.cacheImage('clear_$i', Uint8List(1));
      }
    });

    test('singleton instance', () {
      final instance1 = MxcImageCacheManager.instance;
      final instance2 = MxcImageCacheManager.instance;
      expect(instance1, same(instance2));
    });

    test('cacheImage and getImage', () {
      const eventId = 'test_event_id';
      final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);

      manager.cacheImage(eventId, imageData);
      final cachedImage = manager.getImage(eventId);

      expect(cachedImage, equals(imageData));
    });

    test('cache size limit', () {
      for (int i = 0; i < 35; i++) {
        final eventId = 'test_event_id_$i';
        final imageData = Uint8List.fromList([i, i + 1, i + 2, i + 3, i + 4]);
        manager.cacheImage(eventId, imageData);
      }

      // The cache should only keep the last 30 items
      expect(manager.getImage('test_event_id_0'), isNull);
      expect(manager.getImage('test_event_id_34'), isNotNull);
    });

    test('getImage returns null for non-existent key', () {
      const nonExistentEventId = 'non_existent_id';

      expect(manager.getImage(nonExistentEventId), isNull);
    });

    test('cacheImage overwrites existing image data', () {
      const eventId = 'test_event_id';
      final imageData1 = Uint8List.fromList([1, 2, 3, 4, 5]);
      final imageData2 = Uint8List.fromList([6, 7, 8, 9, 10]);

      manager.cacheImage(eventId, imageData1);
      manager.cacheImage(eventId, imageData2);

      final cachedImage = manager.getImage(eventId);
      expect(cachedImage, equals(imageData2));
    });

    test('cacheImage with empty image data', () {
      const eventId = 'test_event_id';
      final emptyImageData = Uint8List(0);

      manager.cacheImage(eventId, emptyImageData);
      final cachedImage = manager.getImage(eventId);

      expect(cachedImage, equals(emptyImageData));
    });

    test('cacheImage with very large image data', () {
      const eventId = 'test_event_id';
      final largeImageData = Uint8List(1024 * 1024); // 1MB of data

      manager.cacheImage(eventId, largeImageData);
      final cachedImage = manager.getImage(eventId);

      expect(cachedImage, equals(largeImageData));
    });

    test('cache eviction order', () {
      // Fill the cache to its capacity
      for (int i = 0; i < 30; i++) {
        final eventId = 'test_event_id_$i';
        final imageData = Uint8List.fromList([i]);
        manager.cacheImage(eventId, imageData);
      }

      // Verify all items are in the cache
      for (int i = 0; i < 30; i++) {
        expect(manager.getImage('test_event_id_$i'), isNotNull);
      }

      // Add 5 more items to trigger eviction of the oldest items
      for (int i = 30; i < 35; i++) {
        final eventId = 'test_event_id_$i';
        final imageData = Uint8List.fromList([i]);
        manager.cacheImage(eventId, imageData);
      }

      // Verify the 5 oldest items have been evicted
      for (int i = 0; i < 5; i++) {
        expect(manager.getImage('test_event_id_$i'), isNull);
      }

      // Verify the 25 items that were not evicted are still in the cache
      for (int i = 5; i < 30; i++) {
        expect(manager.getImage('test_event_id_$i'), isNotNull);
      }

      // Verify the 5 new items are in the cache
      for (int i = 30; i < 35; i++) {
        expect(manager.getImage('test_event_id_$i'), isNotNull);
      }
    });

    test('cacheImage with empty eventId', () {
      final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);

      manager.cacheImage('', imageData);
      expect(manager.getImage(''), equals(imageData));
    });

    test('cacheImage and getImage with special characters in eventId', () {
      const eventId = 'test!@#\$%^&*()_+{}|:"<>?-=[]\\;\',./`~event_id';
      final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);

      manager.cacheImage(eventId, imageData);
      final cachedImage = manager.getImage(eventId);

      expect(cachedImage, equals(imageData));
    });

    test('multiple cacheImage calls with same eventId', () {
      const eventId = 'test_event_id';
      final imageData1 = Uint8List.fromList([1, 2, 3]);
      final imageData2 = Uint8List.fromList([4, 5, 6]);
      final imageData3 = Uint8List.fromList([7, 8, 9]);

      manager.cacheImage(eventId, imageData1);
      manager.cacheImage(eventId, imageData2);
      manager.cacheImage(eventId, imageData3);

      final cachedImage = manager.getImage(eventId);
      expect(cachedImage, equals(imageData3));
    });
  });
}
