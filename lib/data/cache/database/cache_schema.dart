// lib/data/cache/database/cache_schema.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class CacheSchema {
  static const String tableMediaCache = 'media_cache';
  static const String tableMxcMapping = 'mxc_mapping';

  static Future<void> createTables(ffi.Database db) async {
    // Content storage with deduplication
    await db.execute('''
      CREATE TABLE $tableMediaCache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_hash TEXT NOT NULL UNIQUE,
        media_type TEXT NOT NULL,
        blob BLOB NOT NULL,
        size_bytes INTEGER NOT NULL,
        access_count INTEGER DEFAULT 1,
        last_accessed INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // MXC URL -> content hash mapping (enables dedup)
    await db.execute('''
      CREATE TABLE $tableMxcMapping (
        mxc_url TEXT PRIMARY KEY,
        content_hash TEXT NOT NULL,
        etag TEXT,
        last_modified TEXT,
        width INTEGER,
        height INTEGER,
        is_thumbnail INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (content_hash) REFERENCES $tableMediaCache(content_hash)
      )
    ''');

    // Indexes for LRU eviction
    await db.execute('''
      CREATE INDEX idx_last_accessed ON $tableMediaCache(last_accessed)
    ''');
    await db.execute('''
      CREATE INDEX idx_size ON $tableMediaCache(size_bytes)
    ''');
    await db.execute('''
      CREATE INDEX idx_mxc_hash ON $tableMxcMapping(content_hash)
    ''');
  }

  // Column names as constants
  static const String colId = 'id';
  static const String colContentHash = 'content_hash';
  static const String colMediaType = 'media_type';
  static const String colBlob = 'blob';
  static const String colSizeBytes = 'size_bytes';
  static const String colAccessCount = 'access_count';
  static const String colLastAccessed = 'last_accessed';
  static const String colCreatedAt = 'created_at';
  static const String colMxcUrl = 'mxc_url';
  static const String colEtag = 'etag';
  static const String colLastModified = 'last_modified';
  static const String colWidth = 'width';
  static const String colHeight = 'height';
  static const String colIsThumbnail = 'is_thumbnail';
}
