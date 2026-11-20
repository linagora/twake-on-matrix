import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

// flutter_blurhash's BlurHash reuses one ui.Image across completers, which the image cache disposes.
class BlurHashBackground extends StatelessWidget {
  const BlurHashBackground({
    super.key,
    required this.hash,
    this.fit = BoxFit.fill,
    this.decodingWidth = 32,
    this.decodingHeight = 32,
  });

  final String hash;
  final BoxFit fit;
  final int decodingWidth;
  final int decodingHeight;

  static const _background = ColoredBox(color: Colors.blueGrey);

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image(
        image: BlurHashImage(
          hash,
          decodingWidth: decodingWidth,
          decodingHeight: decodingHeight,
        ),
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
            frame == null && !wasSynchronouslyLoaded ? _background : child,
        errorBuilder: (context, error, stackTrace) => _background,
      ),
    );
  }
}
