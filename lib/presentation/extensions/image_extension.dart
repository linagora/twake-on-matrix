import 'dart:async';

import 'package:flutter/widgets.dart';

extension ImageExtension on Image {
  Future<Size> calculateImageDimension() {
    final completer = Completer<Size>();
    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          final myImage = image.image;
          final Size size =
              Size(myImage.width.toDouble(), myImage.height.toDouble());
          completer.complete(size);
        },
      ),
    );
    return completer.future;
  }
}
