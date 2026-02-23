// lib/data/cache/tier/cache_tier_interface.dart
import 'dart:typed_data';
import '../model/cache_metadata.dart';

/// Abstract interface for cache tier implementations
///
/// Allows different storage backends (SQL, IndexedDB) with unified API
abstract class CacheTierInterface {
  /// Get cached media by MXC URL
  Future<Uint8List?> get(String mxcUrl);

  /// Get metadata for cached media
  Future<CacheMetadata?> getMetadata(String mxcUrl);

  /// Put media into cache with metadata
  Future<void> put({
    required String mxcUrl,
    required Uint8List bytes,
    required String mediaType,
    String? etag,
    String? lastModified,
    int? width,
    int? height,
    bool isThumbnail = false,
  });

  /// Evict least recently used entries to free space
  Future<void> evictLRU({
    required int maxCacheSizeBytes,
    required int targetFreeBytes,
  });

  /// Clear all cached data
  Future<void> clear();

  /// Get total cache size in bytes
  Future<int> size();
}
