import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fluffychat/data/cache/database/cache_database_mobile.dart';
import 'package:fluffychat/data/cache/mxc_cache_manager.dart';
import 'package:fluffychat/data/cache/mxc_cache_config.dart';

void main() {
  late MxcCacheManager cacheManager;
  late CacheDatabaseMobile database;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Mock path_provider
    const MethodChannel(
      'plugins.flutter.io/path_provider',
    ).setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    });
  });

  setUp(() async {
    database = CacheDatabaseMobile();
    cacheManager = MxcCacheManager(
      database: database,
      config: MxcCacheConfig.low(),
    );
    await cacheManager.init();
    // Clear any existing data from previous tests
    await cacheManager.clearAll();
  });

  tearDown(() async {
    await cacheManager.clearAll();
    await cacheManager.dispose();

    // Delete database file to avoid locking issues
    try {
      final dbFile = File('${Directory.systemTemp.path}/mxc_cache.db');
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
    } catch (_) {}
  });

  group('MxcCacheManager', () {
    test('throws StateError when not initialized', () async {
      final uninitializedManager = MxcCacheManager(
        database: CacheDatabaseMobile(),
        config: MxcCacheConfig.low(),
      );

      expect(
        () => uninitializedManager.get(Uri.parse('mxc://example.com/test')),
        throwsStateError,
      );
    });

    test('get returns miss for uncached URI', () async {
      final result = await cacheManager.get(Uri.parse('mxc://example.com/new'));

      expect(result.isMiss, isTrue);
      expect(result.isHit, isFalse);
      expect(result.bytes, isNull);
    });

    test('put then get returns hit', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final uri = Uri.parse('mxc://example.com/test');

      await cacheManager.put(uri, bytes, mediaType: 'image/png');

      final result = await cacheManager.get(uri);

      expect(result.isHit, isTrue);
      expect(result.bytes, equals(bytes));
      expect(result.isFromMemory, isTrue); // First hit from memory
    });

    test('clearMemory clears memory but keeps disk', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final uri = Uri.parse('mxc://example.com/test');

      await cacheManager.put(uri, bytes, mediaType: 'image/png');
      cacheManager.clearMemory();

      final result = await cacheManager.get(uri);

      expect(result.isHit, isTrue);
      expect(result.isFromDisk, isTrue); // Now from disk
    });

    test('clearAll removes all cached data', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final uri = Uri.parse('mxc://example.com/test');

      await cacheManager.put(uri, bytes, mediaType: 'image/png');
      await cacheManager.clearAll();

      final result = await cacheManager.get(uri);

      expect(result.isMiss, isTrue);
    });

    test('builds correct cache key with dimensions', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final uri = Uri.parse('mxc://example.com/test');

      await cacheManager.put(
        uri,
        bytes,
        mediaType: 'image/png',
        width: 100,
        height: 100,
        isThumbnail: true,
      );

      // Same URI without dimensions should miss
      final result1 = await cacheManager.get(uri);
      expect(result1.isMiss, isTrue);

      // Same URI with matching dimensions should hit
      final result2 = await cacheManager.get(
        uri,
        width: 100,
        height: 100,
        isThumbnail: true,
      );
      expect(result2.isHit, isTrue);
    });

    test('builds cache key without dimensions when not thumbnail', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final uri = Uri.parse('mxc://example.com/full');

      await cacheManager.put(
        uri,
        bytes,
        mediaType: 'image/png',
        width: 800,
        height: 600,
        isThumbnail: false, // Not a thumbnail
      );

      // Same URI should hit regardless of dimensions
      final result = await cacheManager.get(uri);
      expect(result.isHit, isTrue);
    });

    test('getStats returns cache statistics', () async {
      final bytes = Uint8List.fromList(List.filled(1000, 1));
      final uri = Uri.parse('mxc://example.com/test');

      await cacheManager.put(uri, bytes, mediaType: 'image/png');

      final stats = await cacheManager.getStats();

      expect(stats.memoryItemCount, equals(1));
      expect(stats.memorySizeBytes, equals(1000));
      expect(stats.diskSizeBytes, equals(1000));
      expect(stats.memoryUtilization, greaterThan(0));
      expect(stats.diskUtilization, greaterThan(0));
    });

    test('evictIfNeeded reduces disk cache size', () async {
      // Fill cache with data
      for (int i = 0; i < 10; i++) {
        await cacheManager.put(
          Uri.parse('mxc://example.com/$i'),
          Uint8List.fromList(List.filled(1000, i)),
          mediaType: 'image/png',
        );
      }

      final statsBefore = await cacheManager.getStats();
      await cacheManager.evictIfNeeded();
      final statsAfter = await cacheManager.getStats();

      // Size should be reduced or stay the same
      expect(
        statsAfter.diskSizeBytes,
        lessThanOrEqualTo(statsBefore.diskSizeBytes),
      );
    });

    test('promotes disk cache hits to memory', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final uri = Uri.parse('mxc://example.com/promote');

      await cacheManager.put(uri, bytes, mediaType: 'image/png');
      cacheManager.clearMemory();

      // First get from disk
      final result1 = await cacheManager.get(uri);
      expect(result1.isFromDisk, isTrue);

      // Second get should be from memory (promoted)
      final result2 = await cacheManager.get(uri);
      expect(result2.isFromMemory, isTrue);
    });

    test('handles multiple URIs correctly', () async {
      final bytes1 = Uint8List.fromList([1, 2, 3]);
      final bytes2 = Uint8List.fromList([4, 5, 6]);
      final uri1 = Uri.parse('mxc://example.com/a');
      final uri2 = Uri.parse('mxc://example.com/b');

      await cacheManager.put(uri1, bytes1, mediaType: 'image/png');
      await cacheManager.put(uri2, bytes2, mediaType: 'image/png');

      final result1 = await cacheManager.get(uri1);
      final result2 = await cacheManager.get(uri2);

      expect(result1.bytes, equals(bytes1));
      expect(result2.bytes, equals(bytes2));
    });

    test('stores and retrieves metadata', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final uri = Uri.parse('mxc://example.com/meta');

      await cacheManager.put(
        uri,
        bytes,
        mediaType: 'image/png',
        etag: '"abc123"',
        lastModified: 'Wed, 21 Oct 2025 07:28:00 GMT',
      );

      cacheManager.clearMemory();

      final result = await cacheManager.get(uri);

      expect(result.metadata?.etag, equals('"abc123"'));
      expect(
        result.metadata?.lastModified,
        equals('Wed, 21 Oct 2025 07:28:00 GMT'),
      );
    });

    test('replaces existing cached entry', () async {
      final bytes1 = Uint8List.fromList([1, 2, 3]);
      final bytes2 = Uint8List.fromList([4, 5, 6, 7, 8]);
      final uri = Uri.parse('mxc://example.com/replace');

      await cacheManager.put(uri, bytes1, mediaType: 'image/png');
      await cacheManager.put(uri, bytes2, mediaType: 'image/png');

      final result = await cacheManager.get(uri);

      expect(result.bytes, equals(bytes2));
    });
  });
}
