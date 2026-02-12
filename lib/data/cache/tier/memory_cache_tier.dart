// lib/data/cache/tier/memory_cache_tier.dart
import 'dart:collection';
import 'dart:typed_data';

class MemoryCacheTier {
  final int maxSizeBytes;
  final int maxItems;

  final LinkedHashMap<String, _MemoryEntry> _cache = LinkedHashMap();
  int _currentSizeBytes = 0;

  MemoryCacheTier({required this.maxSizeBytes, required this.maxItems});

  Uint8List? get(String key) {
    final entry = _cache.remove(key);
    if (entry == null) return null;

    // Move to end (LRU promotion)
    _cache[key] = entry;
    return entry.bytes;
  }

  void put(String key, Uint8List bytes) {
    // Don't cache if single item exceeds limits
    if (bytes.length > maxSizeBytes) return;

    // Remove existing entry if present
    remove(key);

    // Evict until space available
    while (_shouldEvict(bytes.length) && _cache.isNotEmpty) {
      _evictLRU();
    }

    _cache[key] = _MemoryEntry(bytes);
    _currentSizeBytes += bytes.length;
  }

  void remove(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSizeBytes -= entry.bytes.length;
    }
  }

  void clear() {
    _cache.clear();
    _currentSizeBytes = 0;
  }

  bool _shouldEvict(int newItemSize) {
    return _cache.length >= maxItems ||
        _currentSizeBytes + newItemSize > maxSizeBytes;
  }

  void _evictLRU() {
    if (_cache.isEmpty) return;
    final key = _cache.keys.first;
    remove(key);
  }

  int get currentSizeBytes => _currentSizeBytes;
  int get itemCount => _cache.length;

  // Stats for monitoring
  CacheStats get stats => CacheStats(
    itemCount: _cache.length,
    sizeBytes: _currentSizeBytes,
    maxItems: maxItems,
    maxSizeBytes: maxSizeBytes,
  );
}

class _MemoryEntry {
  final Uint8List bytes;

  const _MemoryEntry(this.bytes);
}

class CacheStats {
  final int itemCount;
  final int sizeBytes;
  final int maxItems;
  final int maxSizeBytes;

  const CacheStats({
    required this.itemCount,
    required this.sizeBytes,
    required this.maxItems,
    required this.maxSizeBytes,
  });

  double get utilizationPercent =>
      maxSizeBytes > 0 ? (sizeBytes / maxSizeBytes) * 100 : 0;
}
