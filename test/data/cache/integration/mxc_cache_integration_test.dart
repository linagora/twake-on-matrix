import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fluffychat/data/cache/database/cache_database_mobile.dart';
import 'package:fluffychat/data/cache/mxc_cache_manager.dart';
import 'package:fluffychat/data/cache/mxc_cache_config.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MxcCache Integration', () {
    late MxcCacheManager cacheManager;
    late String dbPath;

    setUp(() async {
      // Create unique database path for each test to avoid locking issues
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      dbPath =
          '${Directory.systemTemp.path}/mxc_cache_integration_test_$timestamp.db';
      final database = CacheDatabaseMobile(customDbPath: dbPath);
      cacheManager = MxcCacheManager(
        database: database,
        config: MxcCacheConfig.low(),
      );
      await cacheManager.init();
      // Clear any existing data
      await cacheManager.clearAll();
    });

    tearDown(() async {
      await cacheManager.clearAll();
      await cacheManager.dispose();

      // Delete test database file
      try {
        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    });

    test('full lifecycle: put -> get -> evict -> miss', () async {
      final uri = Uri.parse('mxc://example.com/lifecycle-test');
      final bytes = Uint8List.fromList(List.filled(100, 42));

      // Put
      await cacheManager.put(uri, bytes, mediaType: 'image/png');

      // Get (memory hit)
      final result1 = await cacheManager.get(uri);
      expect(result1.isHit, isTrue);
      expect(result1.isFromMemory, isTrue);
      expect(result1.bytes, equals(bytes));

      // Clear memory
      cacheManager.clearMemory();

      // Get (disk hit)
      final result2 = await cacheManager.get(uri);
      expect(result2.isHit, isTrue);
      expect(result2.isFromDisk, isTrue);
      expect(result2.bytes, equals(bytes));

      // Clear all
      await cacheManager.clearAll();

      // Get (miss)
      final result3 = await cacheManager.get(uri);
      expect(result3.isMiss, isTrue);
    });

    test('deduplication across multiple URIs', () async {
      final bytes = Uint8List.fromList(List.filled(1000, 1));

      await cacheManager.put(
        Uri.parse('mxc://example.com/a'),
        bytes,
        mediaType: 'image/png',
      );
      await cacheManager.put(
        Uri.parse('mxc://example.com/b'),
        bytes, // Same content
        mediaType: 'image/png',
      );

      final stats = await cacheManager.getStats();

      // Disk should only store content once
      expect(stats.diskSizeBytes, equals(1000));
    });

    test('survives app restart simulation', () async {
      final uri = Uri.parse('mxc://example.com/persist');
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      await cacheManager.put(uri, bytes, mediaType: 'image/png');

      // Simulate restart: dispose and create new manager with same database path
      await cacheManager.dispose();

      final newDatabase = CacheDatabaseMobile(customDbPath: dbPath);
      final newManager = MxcCacheManager(
        database: newDatabase,
        config: MxcCacheConfig.low(),
      );
      await newManager.init();

      // Should find in disk cache
      final result = await newManager.get(uri);
      expect(result.isHit, isTrue);
      expect(result.bytes, equals(bytes));

      await newManager.dispose();
    });

    test('memory tier eviction does not affect disk tier', () async {
      final uri1 = Uri.parse('mxc://example.com/1');
      final uri2 = Uri.parse('mxc://example.com/2');
      final bytes1 = Uint8List.fromList([1, 2, 3]);
      final bytes2 = Uint8List.fromList([4, 5, 6]);

      await cacheManager.put(uri1, bytes1, mediaType: 'image/png');
      await cacheManager.put(uri2, bytes2, mediaType: 'image/png');

      // Clear memory should not affect disk
      cacheManager.clearMemory();

      final result1 = await cacheManager.get(uri1);
      final result2 = await cacheManager.get(uri2);

      expect(result1.isHit, isTrue);
      expect(result1.bytes, equals(bytes1));
      expect(result2.isHit, isTrue);
      expect(result2.bytes, equals(bytes2));
    });

    test('handles large content correctly', () async {
      final largeBytes = Uint8List.fromList(List.filled(1024 * 1024, 1)); // 1MB
      final uri = Uri.parse('mxc://example.com/large');

      await cacheManager.put(uri, largeBytes, mediaType: 'image/jpeg');

      final result = await cacheManager.get(uri);
      expect(result.isHit, isTrue);
      expect(result.bytes?.length, equals(largeBytes.length));
    });

    test('metadata persists across memory clear', () async {
      final uri = Uri.parse('mxc://example.com/meta');
      final bytes = Uint8List.fromList([1, 2, 3]);
      const etag = '"abc123"';
      const lastModified = 'Wed, 21 Oct 2025 07:28:00 GMT';

      await cacheManager.put(
        uri,
        bytes,
        mediaType: 'image/png',
        etag: etag,
        lastModified: lastModified,
      );

      cacheManager.clearMemory();

      final result = await cacheManager.get(uri);
      expect(result.metadata?.etag, equals(etag));
      expect(result.metadata?.lastModified, equals(lastModified));
    });

    test('handles concurrent puts and gets', () async {
      final futures = <Future>[];

      // Concurrent puts
      for (int i = 0; i < 10; i++) {
        futures.add(
          cacheManager.put(
            Uri.parse('mxc://example.com/$i'),
            Uint8List.fromList([i]),
            mediaType: 'image/png',
          ),
        );
      }

      await Future.wait(futures);
      futures.clear();

      // Concurrent gets
      for (int i = 0; i < 10; i++) {
        futures.add(cacheManager.get(Uri.parse('mxc://example.com/$i')));
      }

      final results = await Future.wait(futures);

      for (final result in results) {
        expect(result.isHit, isTrue);
      }
    });

    test('evictIfNeeded maintains cache under limit', () async {
      final config = MxcCacheConfig.low();

      // Fill cache close to limit
      for (int i = 0; i < 100; i++) {
        await cacheManager.put(
          Uri.parse('mxc://example.com/$i'),
          Uint8List.fromList(List.filled(1000, i)),
          mediaType: 'image/png',
        );
      }

      await cacheManager.evictIfNeeded();

      final stats = await cacheManager.getStats();
      expect(stats.diskSizeBytes, lessThanOrEqualTo(config.diskMaxBytes));
    });

    test('thumbnail cache keys differ from full image keys', () async {
      final uri = Uri.parse('mxc://example.com/image');
      final fullBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final thumbBytes = Uint8List.fromList([6, 7, 8]);

      // Store full image
      await cacheManager.put(uri, fullBytes, mediaType: 'image/png');

      // Store thumbnail with same URI
      await cacheManager.put(
        uri,
        thumbBytes,
        mediaType: 'image/png',
        width: 100,
        height: 100,
        isThumbnail: true,
      );

      // Retrieve full image
      final fullResult = await cacheManager.get(uri);
      expect(fullResult.bytes, equals(fullBytes));

      // Retrieve thumbnail
      final thumbResult = await cacheManager.get(
        uri,
        width: 100,
        height: 100,
        isThumbnail: true,
      );
      expect(thumbResult.bytes, equals(thumbBytes));
    });

    test('stats accurately reflect cache state', () async {
      // Initially empty
      var stats = await cacheManager.getStats();
      expect(stats.memoryItemCount, equals(0));
      expect(stats.memorySizeBytes, equals(0));
      expect(stats.diskSizeBytes, equals(0));

      // Add one item
      final bytes = Uint8List.fromList(List.filled(1000, 1));
      await cacheManager.put(
        Uri.parse('mxc://example.com/test'),
        bytes,
        mediaType: 'image/png',
      );

      stats = await cacheManager.getStats();
      expect(stats.memoryItemCount, equals(1));
      expect(stats.memorySizeBytes, equals(1000));
      expect(stats.diskSizeBytes, equals(1000));
      expect(stats.memoryUtilization, greaterThan(0));
      expect(stats.diskUtilization, greaterThan(0));

      // Clear memory only
      cacheManager.clearMemory();

      stats = await cacheManager.getStats();
      expect(stats.memoryItemCount, equals(0));
      expect(stats.memorySizeBytes, equals(0));
      expect(stats.diskSizeBytes, equals(1000)); // Still on disk
    });

    test('handles empty cache gracefully', () async {
      final result = await cacheManager.get(
        Uri.parse('mxc://example.com/nonexistent'),
      );

      expect(result.isMiss, isTrue);
      expect(result.bytes, isNull);
      expect(result.source, isNull);
    });

    test('replaces existing entry with new content', () async {
      final uri = Uri.parse('mxc://example.com/replace');
      final oldBytes = Uint8List.fromList([1, 2, 3]);
      final newBytes = Uint8List.fromList([4, 5, 6, 7, 8]);

      await cacheManager.put(uri, oldBytes, mediaType: 'image/png');
      await cacheManager.put(uri, newBytes, mediaType: 'image/png');

      final result = await cacheManager.get(uri);
      expect(result.bytes, equals(newBytes));

      // Note: diskSizeBytes may include both old and new blobs due to deduplication
      // The old blob is kept until garbage collection
      final stats = await cacheManager.getStats();
      expect(stats.diskSizeBytes, greaterThanOrEqualTo(newBytes.length));
    });

    test('LRU eviction preserves recently accessed items', () async {
      // Add 3 items
      for (int i = 0; i < 3; i++) {
        await cacheManager.put(
          Uri.parse('mxc://example.com/$i'),
          Uint8List.fromList(List.filled(100, i)),
          mediaType: 'image/png',
        );
      }

      // Access item 0 to make it recently used
      cacheManager.clearMemory();
      await cacheManager.get(Uri.parse('mxc://example.com/0'));

      // Fill cache to trigger eviction
      for (int i = 3; i < 100; i++) {
        await cacheManager.put(
          Uri.parse('mxc://example.com/$i'),
          Uint8List.fromList(List.filled(1000, i)),
          mediaType: 'image/png',
        );
      }

      await cacheManager.evictIfNeeded();

      // Recently accessed item 0 should still be present
      final result = await cacheManager.get(Uri.parse('mxc://example.com/0'));
      expect(result.isHit, isTrue);
    });
  });
}
