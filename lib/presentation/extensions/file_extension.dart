import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:matrix/matrix_api_lite/utils/logs.dart';

extension FileExtension on File {
  Future<Size?> getImageDimensions() async {
    try {
      if (!await exists()) {
        throw Exception("File does not exist");
      }

      final ImageProvider provider = FileImage(this);

      final Completer<Size> completer = Completer();

      final ImageStream stream = provider.resolve(const ImageConfiguration());

      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          final Size size = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          info.dispose();
          completer.complete(size);

          stream.removeListener(listener);
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          completer.completeError(exception);
          stream.removeListener(listener);
        },
      );

      stream.addListener(listener);
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          stream.removeListener(listener);
          throw TimeoutException('getImageDimensions timed out');
        },
      );
    } catch (e, s) {
      Logs().e('getImageDimensions error:', e, s);
      return null;
    }
  }
}
