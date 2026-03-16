import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/data/memory/mxc_image_cache_manager.dart';

void main() {
  group('MxcImageCacheManager', () {
    late MxcImageCacheManager manager;

    setUp(() {
      manager = MxcImageCacheManager.instance;
      manager.clear();
    });

    tearDown(() {
      manager.clear();
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

    test('cache entry count limit', () {
      for (int i = 0; i < MxcImageCacheManager.maxEntries + 5; i++) {
        final eventId = 'test_event_id_$i';
        final imageData = Uint8List.fromList([i % 256]);
        manager.cacheImage(eventId, imageData);
      }

      // The first 5 items should have been evicted
      for (int i = 0; i < 5; i++) {
        expect(manager.getImage('test_event_id_$i'), isNull);
      }
      // The rest should still be cached
      expect(manager.getImage('test_event_id_5'), isNotNull);
      expect(
        manager.getImage(
          'test_event_id_${MxcImageCacheManager.maxEntries + 4}',
        ),
        isNotNull,
      );
    });

    test('cache size limit eviction', () {
      // Each image is 10 MB, so 50 MB budget fits 5
      final tenMb = Uint8List(10 * 1024 * 1024);
      for (int i = 0; i < 7; i++) {
        manager.cacheImage('big_$i', tenMb);
      }

      // Only the last 5 should fit (50 MB / 10 MB = 5)
      expect(manager.getImage('big_0'), isNull);
      expect(manager.getImage('big_1'), isNull);
      expect(manager.getImage('big_2'), isNotNull);
      expect(manager.getImage('big_6'), isNotNull);
      expect(
        manager.currentSizeBytes,
        lessThanOrEqualTo(MxcImageCacheManager.maxSizeBytes),
      );
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

    test('cacheImage overwrites and tracks size correctly', () {
      final small = Uint8List(100);
      final big = Uint8List(200);

      manager.cacheImage('id1', small);
      expect(manager.currentSizeBytes, 100);

      // Overwrite with bigger data
      manager.cacheImage('id1', big);
      expect(manager.currentSizeBytes, 200);
      expect(manager.length, 1);
    });

    test('cacheImage with empty image data', () {
      const eventId = 'test_event_id';
      final emptyImageData = Uint8List(0);

      manager.cacheImage(eventId, emptyImageData);
      final cachedImage = manager.getImage(eventId);

      expect(cachedImage, equals(emptyImageData));
    });

    test('LRU promotion - getImage prevents eviction', () {
      // Fill cache with small items up to maxEntries
      for (int i = 0; i < MxcImageCacheManager.maxEntries; i++) {
        manager.cacheImage('item_$i', Uint8List.fromList([i % 256]));
      }

      // Access item_0 to promote it (LRU)
      expect(manager.getImage('item_0'), isNotNull);

      // Add 5 more items to trigger eviction
      for (int i = 0; i < 5; i++) {
        manager.cacheImage('new_item_$i', Uint8List.fromList([i % 256]));
      }

      // item_0 should still be cached (was promoted by getImage)
      expect(manager.getImage('item_0'), isNotNull);

      // item_1 through item_5 should have been evicted (oldest non-promoted)
      for (int i = 1; i <= 5; i++) {
        expect(manager.getImage('item_$i'), isNull);
      }
    });

    test('cache eviction order (FIFO without access)', () {
      // Fill the cache to its capacity
      for (int i = 0; i < MxcImageCacheManager.maxEntries; i++) {
        final eventId = 'test_event_id_$i';
        final imageData = Uint8List.fromList([i % 256]);
        manager.cacheImage(eventId, imageData);
      }

      // Verify all items are in the cache
      for (int i = 0; i < MxcImageCacheManager.maxEntries; i++) {
        expect(manager.getImage('test_event_id_$i'), isNotNull);
      }

      // Note: getImage above promoted all items, so re-fill for clean test
      manager.clear();
      for (int i = 0; i < MxcImageCacheManager.maxEntries; i++) {
        manager.cacheImage('test_event_id_$i', Uint8List.fromList([i % 256]));
      }

      // Add 5 more items to trigger eviction of the oldest items
      for (
        int i = MxcImageCacheManager.maxEntries;
        i < MxcImageCacheManager.maxEntries + 5;
        i++
      ) {
        manager.cacheImage('test_event_id_$i', Uint8List.fromList([i % 256]));
      }

      // Verify the 5 oldest items have been evicted
      for (int i = 0; i < 5; i++) {
        expect(manager.getImage('test_event_id_$i'), isNull);
      }

      // Verify the remaining items are still in the cache
      for (int i = 5; i < MxcImageCacheManager.maxEntries; i++) {
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

    test('clear resets cache completely', () {
      manager.cacheImage('id1', Uint8List(100));
      manager.cacheImage('id2', Uint8List(200));
      expect(manager.length, 2);
      expect(manager.currentSizeBytes, 300);

      manager.clear();
      expect(manager.length, 0);
      expect(manager.currentSizeBytes, 0);
      expect(manager.getImage('id1'), isNull);
    });
  });
}
