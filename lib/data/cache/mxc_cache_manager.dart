// lib/data/cache/mxc_cache_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:matrix/matrix.dart';
import 'database/cache_database_interface.dart';
import 'tier/memory_cache_tier.dart';
import 'tier/cache_tier_interface.dart';
import 'tier/cache_tier_factory.dart';
import 'http_304_validator.dart';
import 'mxc_cache_config.dart';
import 'model/cache_result.dart';
import 'model/cache_metadata.dart';

class MxcCacheManager {
  final CacheDatabaseInterface _database;
  final MxcCacheConfig _config;

  late final MemoryCacheTier _memoryTier;
  late final CacheTierInterface _diskTier;
  late final Http304Validator _validator;

  bool _initialized = false;

  MxcCacheManager({
    required CacheDatabaseInterface database,
    required MxcCacheConfig config,
  }) : _database = database,
       _config = config;

  /// Initialize cache (call once at app start)
  Future<void> init() async {
    if (_initialized) return;

    // Initialize database with cascading fallback (web: wasm -> idb -> memory)
    await _database.init();

    _memoryTier = MemoryCacheTier(
      maxSizeBytes: _config.memoryMaxBytes,
      maxItems: _config.memoryMaxItems,
    );

    // Create appropriate disk tier based on storage type
    // - SQL storage: DiskCacheTier
    // - IndexedDB storage: DiskCacheTierIndexedDb
    _diskTier = await CacheTierFactory.create(_database);

    _validator = Http304Validator();
    _validator.onCacheUpdated = _onCacheUpdated;

    _initialized = true;
    Logs().d(
      'MxcCacheManager: initialized with storage=${_database.storageType.name}, '
      'persistent=${_database.isPersistent}, config=$_config',
    );
  }

  /// Get media from cache (stale-while-revalidate)
  Future<CacheResult> get(
    Uri mxcUri, {
    int? width,
    int? height,
    bool isThumbnail = false,
    Uri? httpUri,
  }) async {
    _ensureInitialized();

    final cacheKey = _buildCacheKey(mxcUri, width, height, isThumbnail);

    // Tier 1: Memory cache (fastest)
    final memoryBytes = _memoryTier.get(cacheKey);
    if (memoryBytes != null) {
      Logs().d('MxcCacheManager: memory hit for $cacheKey');
      return CacheResult.hit(bytes: memoryBytes, source: CacheSource.memory);
    }

    // Tier 2: Disk cache
    final diskBytes = await _diskTier.get(cacheKey);
    if (diskBytes != null) {
      Logs().d('MxcCacheManager: disk hit for $cacheKey');

      // Promote to memory
      _memoryTier.put(cacheKey, diskBytes);

      // Check for background revalidation (SWR)
      final metadata = await _diskTier.getMetadata(cacheKey);
      if (metadata != null && httpUri != null) {
        if (_validator.needsRevalidation(metadata, _config.staleThreshold)) {
          _validator.scheduleRevalidation(
            mxcUrl: cacheKey,
            httpUri: httpUri,
            metadata: metadata,
          );
        }
      }

      return CacheResult.hit(
        bytes: diskBytes,
        source: CacheSource.disk,
        metadata: metadata,
      );
    }

    Logs().d('MxcCacheManager: cache miss for $cacheKey');
    return CacheResult.miss();
  }

  /// Store media in cache
  Future<void> put(
    Uri mxcUri,
    Uint8List bytes, {
    required String mediaType,
    int? width,
    int? height,
    bool isThumbnail = false,
    String? etag,
    String? lastModified,
  }) async {
    _ensureInitialized();

    final cacheKey = _buildCacheKey(mxcUri, width, height, isThumbnail);

    // Store in memory
    _memoryTier.put(cacheKey, bytes);

    // Store in disk (with deduplication)
    await _diskTier.put(
      mxcUrl: cacheKey,
      bytes: bytes,
      mediaType: mediaType,
      etag: etag,
      lastModified: lastModified,
      width: width,
      height: height,
      isThumbnail: isThumbnail,
    );

    Logs().d('MxcCacheManager: stored $cacheKey (${bytes.length} bytes)');
  }

  /// Clear memory cache (call on low memory)
  void clearMemory() {
    if (!_initialized) return;
    _memoryTier.clear();
    Logs().d('MxcCacheManager: memory cache cleared');
  }

  /// Clear all caches
  Future<void> clearAll() async {
    if (!_initialized) return;
    _memoryTier.clear();
    await _diskTier.clear();
    Logs().d('MxcCacheManager: all caches cleared');
  }

  /// Evict old entries to stay within disk limit
  Future<void> evictIfNeeded() async {
    _ensureInitialized();
    await _diskTier.evictLRU(
      maxCacheSizeBytes: _config.diskMaxBytes,
      targetFreeBytes: _config.diskMaxBytes ~/ 10, // 10% headroom
    );
  }

  /// Get metadata for cached entry (for HTTP 304 conditional requests)
  Future<CacheMetadata?> getMetadata(
    Uri mxcUri, {
    int? width,
    int? height,
    bool isThumbnail = false,
  }) async {
    _ensureInitialized();
    final cacheKey = _buildCacheKey(mxcUri, width, height, isThumbnail);
    return await _diskTier.getMetadata(cacheKey);
  }

  /// Get bytes directly from disk tier (for HTTP 304 responses)
  Future<Uint8List?> getFromDisk(
    Uri mxcUri, {
    int? width,
    int? height,
    bool isThumbnail = false,
  }) async {
    _ensureInitialized();
    final cacheKey = _buildCacheKey(mxcUri, width, height, isThumbnail);
    return await _diskTier.get(cacheKey);
  }

  /// Get current cache stats
  Future<MxcCacheStats> getStats() async {
    _ensureInitialized();
    final memoryStats = _memoryTier.stats;
    final diskSize = await _diskTier.size();

    return MxcCacheStats(
      memoryItemCount: memoryStats.itemCount,
      memorySizeBytes: memoryStats.sizeBytes,
      memoryUtilization: memoryStats.utilizationPercent,
      diskSizeBytes: diskSize,
      diskUtilization: _config.diskMaxBytes > 0
          ? (diskSize / _config.diskMaxBytes) * 100
          : 0,
    );
  }

  /// Close database connection
  Future<void> dispose() async {
    if (!_initialized) return;
    _initialized = false;
    _validator.dispose();
    await _database.close();
  }

  String _buildCacheKey(Uri mxcUri, int? w, int? h, bool thumbnail) {
    final base = mxcUri.toString();
    if (!thumbnail || (w == null && h == null)) return base;
    return '$base?w=$w&h=$h&thumb=1';
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('MxcCacheManager not initialized. Call init() first.');
    }
  }

  void _onCacheUpdated(String mxcUrl, Uint8List newBytes) {
    // Update memory cache with fresh content
    _memoryTier.put(mxcUrl, newBytes);
    // Also update disk tier using fire-and-forget
    unawaited(
      _diskTier.put(
        mxcUrl: mxcUrl,
        bytes: newBytes,
        mediaType: 'application/octet-stream',
      ),
    );
    Logs().d('MxcCacheManager: updated $mxcUrl from background revalidation');
  }
}

class MxcCacheStats {
  final int memoryItemCount;
  final int memorySizeBytes;
  final double memoryUtilization;
  final int diskSizeBytes;
  final double diskUtilization;

  const MxcCacheStats({
    required this.memoryItemCount,
    required this.memorySizeBytes,
    required this.memoryUtilization,
    required this.diskSizeBytes,
    required this.diskUtilization,
  });

  @override
  String toString() =>
      'MxcCacheStats(memory: $memoryItemCount items, '
      '${(memorySizeBytes / 1024 / 1024).toStringAsFixed(1)}MB, '
      'disk: ${(diskSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB)';
}
