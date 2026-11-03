import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/extension/mime_type_extension.dart';
import 'package:twake_chat/utils/mime_type_uitls.dart';

void main() {
  group('MimeTypeUitls.getTwakeMimeType', () {
    test('keeps the real type of a .webm, so that it goes as a video', () {
      final mimeType = MimeTypeUitls.getTwakeMimeType('capture.webm');

      expect(mimeType, 'video/webm');
      expect(
        MatrixFile.fromMimeType(
          bytes: Uint8List(0),
          name: 'capture.webm',
          mimeType: mimeType,
        ),
        isA<MatrixVideoFile>(),
      );
    });

    test('still marks a video outside the list', () {
      expect(
        MimeTypeUitls.getTwakeMimeType('clip.mkv'),
        TwakeMimeTypeExtension.defaultUnsupportedVideoMimeType,
      );
    });
  });
}
