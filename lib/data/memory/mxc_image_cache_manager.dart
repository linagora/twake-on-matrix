import 'package:fluffychat/widgets/mxc_image.dart';

class MxcImageCacheManager {
  static final MxcImageCacheManager _instance = MxcImageCacheManager._();
  static MxcImageCacheManager get instance => _instance;
  MxcImageCacheManager._();

  static const _size = 100;
  final Map<EventId, ImageData> _imageCache = {};

  void cacheImage(EventId eventId, ImageData imageData) {
    while (_imageCache.length >= _size) {
      _imageCache.remove(_imageCache.keys.first);
    }
    _imageCache[eventId] = imageData;
  }

  ImageData? getImage(EventId eventId) => _imageCache[eventId];
}
