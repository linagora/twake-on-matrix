import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/data/cache/tier/memory_cache_tier.dart';

void main() {
  group('MemoryCacheTier', () {
    late MemoryCacheTier cache;

    setUp(() {
      cache = MemoryCacheTier(
        maxSizeBytes: 1024, // 1KB for testing
        maxItems: 3,
      );
    });

    test('stores and retrieves bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      cache.put('key1', bytes);

      final result = cache.get('key1');
      expect(result, equals(bytes));
    });

    test('returns null for missing key', () {
      expect(cache.get('nonexistent'), isNull);
    });

    test('evicts LRU entry when max items exceeded', () {
      cache.put('key1', Uint8List.fromList([1]));
      cache.put('key2', Uint8List.fromList([2]));
      cache.put('key3', Uint8List.fromList([3]));

      // Access key1 to make it recently used
      cache.get('key1');

      // Add key4, should evict key2 (LRU)
      cache.put('key4', Uint8List.fromList([4]));

      expect(cache.get('key2'), isNull);
      expect(cache.get('key1'), isNotNull);
      expect(cache.get('key3'), isNotNull);
      expect(cache.get('key4'), isNotNull);
    });

    test('evicts entries when max size exceeded', () {
      cache.put('key1', Uint8List.fromList(List.filled(500, 1)));
      cache.put('key2', Uint8List.fromList(List.filled(500, 2)));

      // Adding 500 more bytes should evict key1
      cache.put('key3', Uint8List.fromList(List.filled(500, 3)));

      expect(cache.get('key1'), isNull);
      expect(cache.currentSizeBytes, lessThanOrEqualTo(1024));
    });

    test('clear removes all entries', () {
      cache.put('key1', Uint8List.fromList([1]));
      cache.put('key2', Uint8List.fromList([2]));

      cache.clear();

      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), isNull);
      expect(cache.itemCount, equals(0));
    });

    test('stats reports correct values', () {
      cache.put('key1', Uint8List.fromList([1, 2, 3]));

      final stats = cache.stats;
      expect(stats.itemCount, equals(1));
      expect(stats.sizeBytes, equals(3));
      expect(stats.maxItems, equals(3));
    });

    test('remove deletes entry and updates size', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      cache.put('key1', bytes);

      expect(cache.itemCount, equals(1));
      expect(cache.currentSizeBytes, equals(5));

      cache.remove('key1');

      expect(cache.itemCount, equals(0));
      expect(cache.currentSizeBytes, equals(0));
      expect(cache.get('key1'), isNull);
    });

    test('put replaces existing entry', () {
      cache.put('key1', Uint8List.fromList([1, 2, 3]));
      expect(cache.currentSizeBytes, equals(3));

      cache.put('key1', Uint8List.fromList([1, 2, 3, 4, 5]));
      expect(cache.currentSizeBytes, equals(5));
      expect(cache.itemCount, equals(1));
    });

    test('does not cache item larger than maxSizeBytes', () {
      final largeBytes = Uint8List.fromList(List.filled(2000, 1));
      cache.put('large', largeBytes);

      expect(cache.get('large'), isNull);
      expect(cache.itemCount, equals(0));
    });

    test('get promotes entry to most recently used', () {
      cache.put('key1', Uint8List.fromList([1]));
      cache.put('key2', Uint8List.fromList([2]));
      cache.put('key3', Uint8List.fromList([3]));

      // Access key1 to promote it
      cache.get('key1');

      // Add key4, should evict key2 (oldest unaccessed)
      cache.put('key4', Uint8List.fromList([4]));

      expect(cache.get('key1'), isNotNull);
      expect(cache.get('key2'), isNull);
      expect(cache.get('key3'), isNotNull);
      expect(cache.get('key4'), isNotNull);
    });

    test('utilizationPercent calculates correctly', () {
      cache.put('key1', Uint8List.fromList(List.filled(512, 1)));

      final stats = cache.stats;
      expect(stats.utilizationPercent, equals(50.0));
    });
  });
}
