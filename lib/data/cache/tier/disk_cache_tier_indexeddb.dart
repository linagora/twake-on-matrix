// lib/data/cache/tier/disk_cache_tier_indexeddb.dart
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:idb_shim/idb.dart';
import 'package:matrix/matrix.dart';
import '../model/cache_metadata.dart';
import 'cache_tier_interface.dart';

/// IndexedDB-based disk cache tier for web (fallback when wasm SQLite fails)
///
/// Uses browser's native IndexedDB API for persistence
class DiskCacheTierIndexedDb implements CacheTierInterface {
  static const String _dbName = 'mxc_cache_idb';
  static const int _dbVersion = 1;
  static const String _storeMediaCache = 'media_cache';
  static const String _storeMxcMapping = 'mxc_mapping';

  final IdbFactory _idbFactory;
  Database? _db;

  DiskCacheTierIndexedDb(this._idbFactory);

  /// Initialize IndexedDB database
  Future<void> init() async {
    if (_db != null) return;

    _db = await _idbFactory.open(
      _dbName,
      version: _dbVersion,
      onUpgradeNeeded: (VersionChangeEvent event) {
        final db = event.database;

        // Create media_cache object store
        if (!db.objectStoreNames.contains(_storeMediaCache)) {
          final mediaStore = db.createObjectStore(
            _storeMediaCache,
            keyPath: 'contentHash',
          );
          // Indexes for LRU eviction
          mediaStore.createIndex('lastAccessed', 'lastAccessed');
          mediaStore.createIndex('accessCount', 'accessCount');
        }

        // Create mxc_mapping object store
        if (!db.objectStoreNames.contains(_storeMxcMapping)) {
          db.createObjectStore(_storeMxcMapping, keyPath: 'mxcUrl');
        }
      },
    );
  }

  @override
  Future<Uint8List?> get(String mxcUrl) async {
    await init();
    final db = _db!;

    final txn = db.transaction([
      _storeMxcMapping,
      _storeMediaCache,
    ], idbModeReadOnly);
    final mappingStore = txn.objectStore(_storeMxcMapping);
    final mediaStore = txn.objectStore(_storeMediaCache);

    try {
      // Get content hash from mapping
      final mapping = await mappingStore.getObject(mxcUrl) as Map?;
      if (mapping == null) return null;

      final contentHash = mapping['contentHash'] as String;

      // Get blob from media cache
      final media = await mediaStore.getObject(contentHash) as Map?;
      if (media == null) return null;

      // Update access stats (in separate transaction)
      await _markAccessed(contentHash);

      // Convert List<int> to Uint8List
      final blobData = media['blob'];
      if (blobData is Uint8List) {
        return blobData;
      } else if (blobData is List) {
        return Uint8List.fromList(List<int>.from(blobData));
      }
      return null;
    } catch (e, s) {
      Logs().e('IndexedDB get failed: $e', e, s);
      return null;
    }
  }

  @override
  Future<CacheMetadata?> getMetadata(String mxcUrl) async {
    await init();
    final db = _db!;

    final txn = db.transaction(_storeMxcMapping, idbModeReadOnly);
    final store = txn.objectStore(_storeMxcMapping);

    try {
      final mapping = await store.getObject(mxcUrl) as Map?;
      if (mapping == null) return null;

      return CacheMetadata(
        etag: mapping['etag'] as String?,
        lastModified: mapping['lastModified'] as String?,
        width: mapping['width'] as int?,
        height: mapping['height'] as int?,
        isThumbnail: (mapping['isThumbnail'] as int?) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          mapping['createdAt'] as int,
        ),
      );
    } catch (e, s) {
      Logs().e('IndexedDB getMetadata failed: $e', e, s);
      return null;
    }
  }

  @override
  Future<void> put({
    required String mxcUrl,
    required Uint8List bytes,
    required String mediaType,
    String? etag,
    String? lastModified,
    int? width,
    int? height,
    bool isThumbnail = false,
  }) async {
    await init();
    final db = _db!;
    final contentHash = _computeHash(bytes);
    final now = DateTime.now().millisecondsSinceEpoch;

    final txn = db.transaction([
      _storeMediaCache,
      _storeMxcMapping,
    ], idbModeReadWrite);
    final mediaStore = txn.objectStore(_storeMediaCache);
    final mappingStore = txn.objectStore(_storeMxcMapping);

    try {
      // Check if content already exists
      final existing = await mediaStore.getObject(contentHash);

      if (existing == null) {
        // Insert new content blob
        await mediaStore.put({
          'contentHash': contentHash,
          'mediaType': mediaType,
          'blob': bytes,
          'sizeBytes': bytes.length,
          'accessCount': 1,
          'lastAccessed': now,
          'createdAt': now,
        });
      }

      // Upsert MXC mapping
      await mappingStore.put({
        'mxcUrl': mxcUrl,
        'contentHash': contentHash,
        'etag': etag,
        'lastModified': lastModified,
        'width': width,
        'height': height,
        'isThumbnail': isThumbnail ? 1 : 0,
        'createdAt': now,
      });

      await txn.completed;
    } catch (e, s) {
      Logs().e('IndexedDB put failed: $e', e, s);
      rethrow;
    }
  }

  @override
  Future<void> evictLRU({
    required int maxCacheSizeBytes,
    required int targetFreeBytes,
  }) async {
    await init();
    final db = _db!;

    final txn = db.transaction([
      _storeMediaCache,
      _storeMxcMapping,
    ], idbModeReadWrite);
    final mediaStore = txn.objectStore(_storeMediaCache);
    final mappingStore = txn.objectStore(_storeMxcMapping);

    try {
      // Get all entries and calculate total size
      final entries = <Map<String, dynamic>>[];
      int currentSize = 0;

      final cursorStream = mediaStore.openCursor(autoAdvance: true);
      await for (final cursorWithValue in cursorStream) {
        final value = cursorWithValue.value as Map;
        final entry = Map<String, dynamic>.from(value);
        entries.add(entry);
        currentSize += entry['sizeBytes'] as int;
      }

      if (currentSize <= maxCacheSizeBytes) return;

      final bytesToFree = currentSize - (maxCacheSizeBytes - targetFreeBytes);

      // Sort by LRU (accessCount ASC, lastAccessed ASC)
      entries.sort((a, b) {
        final countCompare = (a['accessCount'] as int).compareTo(
          b['accessCount'] as int,
        );
        if (countCompare != 0) return countCompare;
        return (a['lastAccessed'] as int).compareTo(b['lastAccessed'] as int);
      });

      // First pass: collect hashes to delete
      final hashesToDelete = <String>{};
      int freedBytes = 0;
      for (final entry in entries) {
        if (freedBytes >= bytesToFree) break;
        hashesToDelete.add(entry['contentHash'] as String);
        freedBytes += entry['sizeBytes'] as int;
      }

      // Single pass deletion of mappings
      final mappingCursorStream = mappingStore.openCursor(autoAdvance: true);
      await for (final cursor in mappingCursorStream) {
        final mapping = cursor.value as Map;
        if (hashesToDelete.contains(mapping['contentHash'])) {
          cursor.delete();
        }
      }

      // Delete media blobs
      for (final hash in hashesToDelete) {
        await mediaStore.delete(hash);
      }

      await txn.completed;
    } catch (e, s) {
      Logs().e('IndexedDB evictLRU failed: $e', e, s);
    }
  }

  @override
  Future<void> clear() async {
    await init();
    final db = _db!;

    final txn = db.transaction([
      _storeMediaCache,
      _storeMxcMapping,
    ], idbModeReadWrite);

    try {
      await txn.objectStore(_storeMxcMapping).clear();
      await txn.objectStore(_storeMediaCache).clear();
      await txn.completed;
    } catch (e, s) {
      Logs().e('IndexedDB clear failed: $e', e, s);
    }
  }

  @override
  Future<int> size() async {
    await init();
    final db = _db!;

    final txn = db.transaction(_storeMediaCache, idbModeReadOnly);
    final store = txn.objectStore(_storeMediaCache);

    try {
      int total = 0;
      final cursorStream = store.openCursor(autoAdvance: true);
      await for (final cursorWithValue in cursorStream) {
        final value = cursorWithValue.value as Map;
        total += value['sizeBytes'] as int;
      }
      return total;
    } catch (e, s) {
      Logs().e('IndexedDB size failed: $e', e, s);
      return 0;
    }
  }

  Future<void> _markAccessed(String contentHash) async {
    final db = _db!;
    final now = DateTime.now().millisecondsSinceEpoch;

    final txn = db.transaction(_storeMediaCache, idbModeReadWrite);
    final store = txn.objectStore(_storeMediaCache);

    try {
      final media = await store.getObject(contentHash) as Map?;
      if (media != null) {
        final updated = Map<String, dynamic>.from(media);
        updated['accessCount'] = (updated['accessCount'] as int) + 1;
        updated['lastAccessed'] = now;
        await store.put(updated);
        await txn.completed;
      }
    } catch (e, s) {
      Logs().w('IndexedDB _markAccessed failed: $e', e, s);
    }
  }

  String _computeHash(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Close the database
  Future<void> close() async {
    _db?.close();
    _db = null;
  }
}
