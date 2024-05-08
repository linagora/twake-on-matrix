import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:matrix/matrix.dart';

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    required this.event,
    required this.width,
    required this.height,
    required this.fit,
  });

  final Event event;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (event.messageType == MessageTypes.Sticker) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }
    final String blurHashString =
        event.blurHash ?? AppConfig.defaultImageBlurHash;
    final ratio = event.infoMap['w'] is int && event.infoMap['h'] is int
        ? event.infoMap['w'] / event.infoMap['h']
        : 1.0;
    var width = MessageContentStyle.blurhashSize;
    var height = MessageContentStyle.blurhashSize;
    if (ratio > 1.0) {
      height = (width / ratio).round();
    } else {
      width = (height * ratio).round();
    }
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: SizedBox(
        width: this.width,
        height: this.height,
        child: BlurHash(
          hash: blurHashString,
          decodingWidth: width,
          decodingHeight: height,
          imageFit: fit,
        ),
      ),
    );
  }
}
