import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fluffychat/data/cache/database/cache_database_mobile.dart';
import 'package:fluffychat/data/cache/tier/disk_cache_tier.dart';

void main() {
  late CacheDatabaseMobile database;
  late DiskCacheTier diskTier;
  late String dbPath;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create unique database path for each test to avoid locking issues
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    dbPath = '${Directory.systemTemp.path}/mxc_cache_disk_test_$timestamp.db';
    database = CacheDatabaseMobile(customDbPath: dbPath);
    diskTier = DiskCacheTier(database);
    // Initialize and clear any existing data
    await (await database.database).delete('mxc_mapping');
    await (await database.database).delete('media_cache');
  });

  tearDown(() async {
    await diskTier.clear();
    await database.close();

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

  group('DiskCacheTier', () {
    test('stores and retrieves bytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      await diskTier.put(
        mxcUrl: 'mxc://example.com/abc123',
        bytes: bytes,
        mediaType: 'image/png',
      );

      final result = await diskTier.get('mxc://example.com/abc123');
      expect(result, equals(bytes));
    });

    test('returns null for missing mxcUrl', () async {
      final result = await diskTier.get('mxc://example.com/nonexistent');
      expect(result, isNull);
    });

    test('deduplicates identical content', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      await diskTier.put(
        mxcUrl: 'mxc://example.com/abc',
        bytes: bytes,
        mediaType: 'image/png',
      );
      await diskTier.put(
        mxcUrl: 'mxc://example.com/xyz',
        bytes: bytes, // Same content
        mediaType: 'image/png',
      );

      // Both URLs should return same content
      final result1 = await diskTier.get('mxc://example.com/abc');
      final result2 = await diskTier.get('mxc://example.com/xyz');
      expect(result1, equals(bytes));
      expect(result2, equals(bytes));

      // Size should only count blob once
      final size = await diskTier.size();
      expect(size, equals(5)); // Not 10
    });

    test('returns metadata with etag', () async {
      await diskTier.put(
        mxcUrl: 'mxc://example.com/abc',
        bytes: Uint8List.fromList([1, 2, 3]),
        mediaType: 'image/png',
        etag: '"abc123"',
        lastModified: 'Wed, 21 Oct 2025 07:28:00 GMT',
      );

      final metadata = await diskTier.getMetadata('mxc://example.com/abc');
      expect(metadata?.etag, equals('"abc123"'));
      expect(metadata?.lastModified, equals('Wed, 21 Oct 2025 07:28:00 GMT'));
    });

    test('stores dimensions for thumbnails', () async {
      await diskTier.put(
        mxcUrl: 'mxc://example.com/thumb',
        bytes: Uint8List.fromList([1, 2, 3]),
        mediaType: 'image/png',
        width: 100,
        height: 100,
        isThumbnail: true,
      );

      final metadata = await diskTier.getMetadata('mxc://example.com/thumb');
      expect(metadata?.width, equals(100));
      expect(metadata?.height, equals(100));
      expect(metadata?.isThumbnail, isTrue);
    });

    test('evicts LRU entries', () async {
      // Add 3 entries of 100 bytes each = 300 bytes total
      for (int i = 0; i < 3; i++) {
        await diskTier.put(
          mxcUrl: 'mxc://example.com/$i',
          bytes: Uint8List.fromList(List.filled(100, i)),
          mediaType: 'image/png',
        );
      }

      // Access entry 0 to make it recently used
      await diskTier.get('mxc://example.com/0');

      // Evict to 120 bytes max (should remove only entry 1, the LRU)
      // bytesToFree = 300 - (120 - 10) = 190 bytes
      // This will evict entries 1 and 2, leaving only 0
      await diskTier.evictLRU(maxCacheSizeBytes: 120, targetFreeBytes: 10);

      // Only entry 0 should remain (most recently accessed)
      expect(await diskTier.get('mxc://example.com/0'), isNotNull);
      expect(await diskTier.get('mxc://example.com/1'), isNull);
      expect(await diskTier.get('mxc://example.com/2'), isNull);
    });

    test('evictLRU does not evict if under limit', () async {
      await diskTier.put(
        mxcUrl: 'mxc://example.com/small',
        bytes: Uint8List.fromList([1, 2, 3]),
        mediaType: 'image/png',
      );

      await diskTier.evictLRU(maxCacheSizeBytes: 1000, targetFreeBytes: 100);

      expect(await diskTier.get('mxc://example.com/small'), isNotNull);
    });

    test('clear removes all entries', () async {
      await diskTier.put(
        mxcUrl: 'mxc://example.com/a',
        bytes: Uint8List.fromList([1, 2, 3]),
        mediaType: 'image/png',
      );
      await diskTier.put(
        mxcUrl: 'mxc://example.com/b',
        bytes: Uint8List.fromList([4, 5, 6]),
        mediaType: 'image/png',
      );

      await diskTier.clear();

      expect(await diskTier.get('mxc://example.com/a'), isNull);
      expect(await diskTier.get('mxc://example.com/b'), isNull);
      expect(await diskTier.size(), equals(0));
    });

    test('size returns total bytes stored', () async {
      await diskTier.put(
        mxcUrl: 'mxc://example.com/a',
        bytes: Uint8List.fromList(List.filled(100, 1)),
        mediaType: 'image/png',
      );
      await diskTier.put(
        mxcUrl: 'mxc://example.com/b',
        bytes: Uint8List.fromList(List.filled(200, 2)),
        mediaType: 'image/png',
      );

      final size = await diskTier.size();
      expect(size, equals(300));
    });

    test('replaces existing mapping', () async {
      final bytes1 = Uint8List.fromList([1, 2, 3]);
      final bytes2 = Uint8List.fromList([4, 5, 6, 7]);

      await diskTier.put(
        mxcUrl: 'mxc://example.com/test',
        bytes: bytes1,
        mediaType: 'image/png',
      );

      await diskTier.put(
        mxcUrl: 'mxc://example.com/test',
        bytes: bytes2,
        mediaType: 'image/png',
      );

      final result = await diskTier.get('mxc://example.com/test');
      expect(result, equals(bytes2));
    });

    test('tracks access count correctly', () async {
      await diskTier.put(
        mxcUrl: 'mxc://example.com/tracked',
        bytes: Uint8List.fromList([1, 2, 3]),
        mediaType: 'image/png',
      );

      // Access multiple times
      await diskTier.get('mxc://example.com/tracked');
      await diskTier.get('mxc://example.com/tracked');
      await diskTier.get('mxc://example.com/tracked');

      // The access count should be updated (verified through eviction behavior)
      // Create another entry and verify the frequently accessed one is kept
      await diskTier.put(
        mxcUrl: 'mxc://example.com/new',
        bytes: Uint8List.fromList(List.filled(100, 1)),
        mediaType: 'image/png',
      );

      await diskTier.evictLRU(maxCacheSizeBytes: 50, targetFreeBytes: 10);

      // Frequently accessed should remain
      expect(await diskTier.get('mxc://example.com/tracked'), isNotNull);
    });
  });
}
