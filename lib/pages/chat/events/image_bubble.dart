import 'package:fluffychat/pages/chat/events/image_builder_web.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/widgets/mxc_image.dart';

class ImageBubble extends StatelessWidget {
  final Event event;
  final BoxFit fit;
  final bool maxSize;
  final bool thumbnailOnly;
  final bool animated;
  final double width;
  final double height;
  final bool rounded;
  final void Function()? onTapPreview;
  final void Function()? onTapSelectMode;
  final bool isPreview;
  final Duration animationDuration;

  final String? thumbnailCacheKey;
  final Map<EventId, ImageData>? thumbnailCacheMap;
  final bool noResizeThumbnail;

  const ImageBubble(
    this.event, {
    this.maxSize = true,
    this.fit = BoxFit.cover,
    this.thumbnailOnly = true,
    this.width = 256,
    this.height = 300,
    this.animated = false,
    this.rounded = true,
    this.onTapSelectMode,
    this.onTapPreview,
    this.animationDuration = const Duration(milliseconds: 500),
    this.thumbnailCacheKey,
    this.thumbnailCacheMap,
    this.noResizeThumbnail = false,
    this.isPreview = true,
    Key? key,
  }) : super(key: key);

  static const animationSwitcherDuration = Duration(seconds: 1);

  @override
  Widget build(BuildContext context) {
    final bubbleWidth = MessageContentStyle.imageBubbleWidth(width);
    final bubbleHeight = MessageContentStyle.imageBubbleWidth(height);
    return Container(
      decoration: BoxDecoration(
        borderRadius: rounded
            ? MessageContentStyle.borderRadiusBubble
            : BorderRadius.zero,
      ),
      constraints: maxSize
          ? BoxConstraints(
              maxWidth: bubbleWidth,
              maxHeight: bubbleHeight,
            )
          : null,
      child: ClipRRect(
        borderRadius: rounded
            ? MessageContentStyle.borderRadiusBubble
            : BorderRadius.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: bubbleWidth,
              height: bubbleHeight,
              child: const BlurHash(hash: MessageContentStyle.defaultBlurHash),
            ),
            PlatformInfos.isWeb &&
                    event.isEventEncrypted(isThumbnail: thumbnailOnly)
                ? ImageBuilderWeb(
                    event: event,
                    isThumbnail: thumbnailOnly,
                    width: width,
                    height: height,
                    onTapPreview: onTapPreview,
                    onTapSelectMode: onTapSelectMode,
                    fit: fit,
                  )
                : MxcImage(
                    event: event,
                    width: width,
                    height: height,
                    fit: fit,
                    animated: animated,
                    isThumbnail: thumbnailOnly,
                    placeholder: (context) => ImagePlaceholder(
                      event: event,
                      width: width,
                      height: height,
                      fit: fit,
                    ),
                    onTapPreview: onTapPreview,
                    onTapSelectMode: onTapSelectMode,
                    isPreview: isPreview,
                    animationDuration: animationDuration,
                    cacheKey: thumbnailCacheKey,
                    cacheMap: thumbnailCacheMap,
                    noResize: noResizeThumbnail,
                  ),
          ],
        ),
      ),
    );
  }
}

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
    var width = 32;
    var height = 32;
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
