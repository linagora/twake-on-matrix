// lib/data/cache/tier/cache_tier_factory.dart
import 'package:flutter/foundation.dart';
import '../database/cache_database_interface.dart';
import 'cache_tier_interface.dart';
import 'disk_cache_tier.dart';
import 'disk_cache_tier_indexeddb_web.dart'
    if (dart.library.io) 'disk_cache_tier_indexeddb_stub.dart';

/// Factory for creating platform and storage-type specific cache tiers
class CacheTierFactory {
  /// Create appropriate cache tier based on database storage type
  ///
  /// - SQL storage (mobile/desktop/web-wasm): DiskCacheTier
  /// - IndexedDB storage (web fallback): DiskCacheTierIndexedDb
  /// - Memory storage: DiskCacheTier (in-memory SQL)
  static Future<CacheTierInterface> create(
    CacheDatabaseInterface database,
  ) async {
    // For IndexedDB storage, use native IndexedDB implementation
    if (kIsWeb && database.storageType == CacheStorageType.indexedDb) {
      return await _createIndexedDbTier();
    }

    // For all other cases (SQL-based), use DiskCacheTier
    return DiskCacheTier(database);
  }

  static Future<CacheTierInterface> _createIndexedDbTier() async {
    final tier = createIndexedDbTierImpl();
    await tier.init();
    return tier;
  }
}
