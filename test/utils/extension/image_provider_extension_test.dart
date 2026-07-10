import 'dart:typed_data';

import 'package:fluffychat/utils/extension/image_provider_extension.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageProviderExtension.resizeToFit', () {
    late MemoryImage imageProvider;

    setUp(() {
      imageProvider = MemoryImage(Uint8List.fromList([1]));
    });

    test('returns original provider when no cache size is requested', () {
      expect(imageProvider.resizeToFit(), same(imageProvider));
    });

    test('uses fit policy to preserve source aspect ratio', () {
      final resizedProvider = imageProvider.resizeToFit(
        cacheWidth: 932,
        cacheHeight: 300,
      );

      expect(resizedProvider, isA<ResizeImage>());
      final resizeImage = resizedProvider as ResizeImage;
      expect(resizeImage.imageProvider, same(imageProvider));
      expect(resizeImage.width, 932);
      expect(resizeImage.height, 300);
      expect(resizeImage.policy, ResizeImagePolicy.fit);
    });
  });
}
