import 'dart:typed_data';
import 'dart:ui';

import 'package:matrix/matrix_api_lite/utils/logs.dart';

extension Uint8listExtension on Uint8List {
  Future<Size?> get imageSize async {
    Codec? codec;
    try {
      codec = await instantiateImageCodec(this);
      final FrameInfo frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      Logs().e('Uint8listExtension::imageSize: Error getting image size', e);
      return null;
    } finally {
      codec?.dispose();
    }
  }
}
