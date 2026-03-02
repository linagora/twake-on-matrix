import 'dart:io';
import 'dart:ui';
import 'package:matrix/matrix_api_lite/utils/logs.dart';

extension FileExtension on File {
  Future<Size?> getImageDimensions() async {
    Codec? codec;
    try {
      if (!await exists()) return null;
      final bytes = await readAsBytes();
      codec = await instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      return size;
    } catch (e, s) {
      Logs().e('getImageDimensions error:', e, s);
      return null;
    } finally {
      codec?.dispose();
    }
  }
}
