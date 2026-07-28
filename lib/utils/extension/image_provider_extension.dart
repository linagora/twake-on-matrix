import 'package:flutter/painting.dart';

extension ImageProviderExtension on ImageProvider<Object> {
  ImageProvider<Object> resizeToFit({int? cacheWidth, int? cacheHeight}) {
    assert(cacheWidth == null || cacheWidth > 0);
    assert(cacheHeight == null || cacheHeight > 0);

    if (cacheWidth == null && cacheHeight == null) {
      return this;
    }

    return ResizeImage(
      this,
      width: cacheWidth,
      height: cacheHeight,
      policy: ResizeImagePolicy.fit,
    );
  }
}
