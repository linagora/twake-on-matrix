import 'package:fluffychat/widgets/mxc_image.dart';

class MxcImageCacheManager {
  static final MxcImageCacheManager _instance = MxcImageCacheManager._();
  static MxcImageCacheManager get instance => _instance;
  MxcImageCacheManager._();

  static const _maxCount = 100;
  static const _maxBytes = 50 * 1024 * 1024; // 50 MB

  final Map<EventId, ImageData> _imageCache = {};
  int _totalBytes = 0;

  void cacheImage(EventId eventId, ImageData imageData) {
    // Images larger than the total budget are never cached — they would
    // immediately violate the invariant even in an empty cache.
    if (imageData.length > _maxBytes) return;
    // Remove existing entry first to avoid double-counting on update
    // and to prevent evicting an unrelated LRU entry on key overwrite.
    final existing = _imageCache.remove(eventId);
    if (existing != null) {
      _totalBytes -= existing.length;
    }
    while (_imageCache.isNotEmpty &&
        (_imageCache.length >= _maxCount ||
            _totalBytes + imageData.length > _maxBytes)) {
      final oldest = _imageCache.keys.first;
      _totalBytes -= _imageCache[oldest]!.length;
      _imageCache.remove(oldest);
    }
    _imageCache[eventId] = imageData;
    _totalBytes += imageData.length;
    assert(
      _totalBytes == _imageCache.values.fold<int>(0, (s, e) => s + e.length),
      'MxcImageCacheManager: _totalBytes drifted',
    );
  }

  ImageData? getImage(EventId eventId) {
    // Remove-and-reinsert promotes the entry to the end of iteration
    // order, making eviction in cacheImage() true LRU instead of FIFO.
    final data = _imageCache.remove(eventId);
    if (data != null) _imageCache[eventId] = data;
    return data;
  }

  void clear() {
    _imageCache.clear();
    _totalBytes = 0;
  }
}
