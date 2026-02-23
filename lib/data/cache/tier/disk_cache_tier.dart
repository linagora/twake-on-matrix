// lib/data/cache/tier/disk_cache_tier.dart
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show ConflictAlgorithm;
import '../database/cache_database_interface.dart';
import '../database/cache_schema.dart';
import '../model/cache_metadata.dart';
import 'cache_tier_interface.dart';

/// SQL-based disk cache tier for mobile/desktop and web (wasm SQLite)
class DiskCacheTier implements CacheTierInterface {
  final CacheDatabaseInterface _cacheDatabase;

  DiskCacheTier(this._cacheDatabase);

  @override
  Future<Uint8List?> get(String mxcUrl) async {
    final db = await _cacheDatabase.database;

    // Get content hash from mapping
    final mapping = await db.query(
      CacheSchema.tableMxcMapping,
      columns: [CacheSchema.colContentHash],
      where: '${CacheSchema.colMxcUrl} = ?',
      whereArgs: [mxcUrl],
    );

    if (mapping.isEmpty) return null;

    final contentHash = mapping.first[CacheSchema.colContentHash] as String;

    // Update access stats and get blob
    await _markAccessed(db, contentHash);

    final result = await db.query(
      CacheSchema.tableMediaCache,
      columns: [CacheSchema.colBlob],
      where: '${CacheSchema.colContentHash} = ?',
      whereArgs: [contentHash],
    );

    if (result.isEmpty) return null;
    return result.first[CacheSchema.colBlob] as Uint8List;
  }

  @override
  Future<CacheMetadata?> getMetadata(String mxcUrl) async {
    final db = await _cacheDatabase.database;

    final result = await db.query(
      CacheSchema.tableMxcMapping,
      where: '${CacheSchema.colMxcUrl} = ?',
      whereArgs: [mxcUrl],
    );

    if (result.isEmpty) return null;
    return CacheMetadata.fromMap(result.first);
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
    final db = await _cacheDatabase.database;
    final contentHash = _computeHash(bytes);
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // Check if content already exists (deduplication)
      final existing = await txn.query(
        CacheSchema.tableMediaCache,
        columns: [CacheSchema.colContentHash],
        where: '${CacheSchema.colContentHash} = ?',
        whereArgs: [contentHash],
      );

      if (existing.isEmpty) {
        // Insert new content blob
        await txn.insert(CacheSchema.tableMediaCache, {
          CacheSchema.colContentHash: contentHash,
          CacheSchema.colMediaType: mediaType,
          CacheSchema.colBlob: bytes,
          CacheSchema.colSizeBytes: bytes.length,
          CacheSchema.colAccessCount: 1,
          CacheSchema.colLastAccessed: now,
          CacheSchema.colCreatedAt: now,
        });
      }

      // Upsert MXC mapping
      await txn.insert(CacheSchema.tableMxcMapping, {
        CacheSchema.colMxcUrl: mxcUrl,
        CacheSchema.colContentHash: contentHash,
        CacheSchema.colEtag: etag,
        CacheSchema.colLastModified: lastModified,
        CacheSchema.colWidth: width,
        CacheSchema.colHeight: height,
        CacheSchema.colIsThumbnail: isThumbnail ? 1 : 0,
        CacheSchema.colCreatedAt: now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> evictLRU({
    required int maxCacheSizeBytes,
    required int targetFreeBytes,
  }) async {
    final db = await _cacheDatabase.database;

    await db.transaction((txn) async {
      // Get current size
      final sizeResult = await txn.rawQuery(
        'SELECT SUM(${CacheSchema.colSizeBytes}) as total FROM ${CacheSchema.tableMediaCache}',
      );
      final currentSize = (sizeResult.first['total'] as int?) ?? 0;

      if (currentSize <= maxCacheSizeBytes) return;

      final bytesToFree = currentSize - (maxCacheSizeBytes - targetFreeBytes);
      int freedBytes = 0;

      // Get entries ordered by LRU
      final toEvict = await txn.rawQuery('''
        SELECT ${CacheSchema.colContentHash}, ${CacheSchema.colSizeBytes}
        FROM ${CacheSchema.tableMediaCache}
        ORDER BY ${CacheSchema.colAccessCount} ASC, ${CacheSchema.colLastAccessed} ASC
      ''');

      for (final row in toEvict) {
        if (freedBytes >= bytesToFree) break;

        final hash = row[CacheSchema.colContentHash] as String;
        final size = row[CacheSchema.colSizeBytes] as int;

        // Delete mapping first (FK)
        await txn.delete(
          CacheSchema.tableMxcMapping,
          where: '${CacheSchema.colContentHash} = ?',
          whereArgs: [hash],
        );

        // Delete blob
        await txn.delete(
          CacheSchema.tableMediaCache,
          where: '${CacheSchema.colContentHash} = ?',
          whereArgs: [hash],
        );

        freedBytes += size;
      }
    });
  }

  @override
  Future<void> clear() async {
    final db = await _cacheDatabase.database;
    await db.delete(CacheSchema.tableMxcMapping);
    await db.delete(CacheSchema.tableMediaCache);
  }

  @override
  Future<int> size() async {
    final db = await _cacheDatabase.database;
    final result = await db.rawQuery(
      'SELECT SUM(${CacheSchema.colSizeBytes}) as total FROM ${CacheSchema.tableMediaCache}',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> _markAccessed(ffi.Database db, String contentHash) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawUpdate(
      '''
      UPDATE ${CacheSchema.tableMediaCache}
      SET ${CacheSchema.colAccessCount} = ${CacheSchema.colAccessCount} + 1,
          ${CacheSchema.colLastAccessed} = ?
      WHERE ${CacheSchema.colContentHash} = ?
    ''',
      [now, contentHash],
    );
  }

  String _computeHash(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }
}
