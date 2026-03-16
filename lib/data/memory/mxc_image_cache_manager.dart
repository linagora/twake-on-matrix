import 'package:fluffychat/widgets/mxc_image.dart';

class MxcImageCacheManager {
  static final MxcImageCacheManager _instance = MxcImageCacheManager._();
  static MxcImageCacheManager get instance => _instance;
  MxcImageCacheManager._();

  /// Maximum number of cached entries.
  static const maxEntries = 300;

  /// Maximum total size in bytes (50 MB).
  static const maxSizeBytes = 50 * 1024 * 1024;

  final Map<EventId, ImageData> _imageCache = {};
  int _currentSizeBytes = 0;

  /// Current total size of cached image data in bytes.
  int get currentSizeBytes => _currentSizeBytes;

  /// Current number of cached entries.
  int get length => _imageCache.length;

  void cacheImage(EventId eventId, ImageData imageData) {
    // If already cached, remove old entry to update size tracking
    final existing = _imageCache.remove(eventId);
    if (existing != null) {
      _currentSizeBytes -= existing.lengthInBytes;
    }

    final newSize = imageData.lengthInBytes;

    // Evict oldest entries until both limits are satisfied
    while (_imageCache.isNotEmpty &&
        (_imageCache.length >= maxEntries ||
            _currentSizeBytes + newSize > maxSizeBytes)) {
      _evictOldest();
    }

    _imageCache[eventId] = imageData;
    _currentSizeBytes += newSize;
  }

  /// Returns the cached image data and promotes the entry (LRU).
  ImageData? getImage(EventId eventId) {
    final data = _imageCache.remove(eventId);
    if (data == null) return null;
    // Re-insert at the end to mark as most recently used
    _imageCache[eventId] = data;
    return data;
  }

  /// Clears all cached entries.
  void clear() {
    _imageCache.clear();
    _currentSizeBytes = 0;
  }

  void _evictOldest() {
    final oldestKey = _imageCache.keys.first;
    final evicted = _imageCache.remove(oldestKey);
    if (evicted != null) {
      _currentSizeBytes -= evicted.lengthInBytes;
    }
  }
}
