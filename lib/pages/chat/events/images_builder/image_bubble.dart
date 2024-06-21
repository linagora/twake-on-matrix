import 'dart:typed_data';

import 'package:fluffychat/pages/chat/events/images_builder/image_builder_web.dart';
import 'package:fluffychat/pages/chat/events/images_builder/image_placeholder.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
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
  final Uint8List? imageData;

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
    this.imageData,
    super.key,
  });

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
        child: (PlatformInfos.isWeb &&
                !event.isEventEncrypted(isThumbnail: thumbnailOnly))
            ? UnencryptedImageBuilderWeb(
                event: event,
                isThumbnail: thumbnailOnly,
                width: width,
                height: height,
                onTapPreview: onTapPreview,
                onTapSelectMode: onTapSelectMode,
                fit: fit,
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: bubbleWidth,
                    height: bubbleHeight,
                    child: const BlurHash(
                      hash: MessageContentStyle.defaultBlurHash,
                    ),
                  ),
                  MxcImage(
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
                    imageData: imageData,
                  ),
                ],
              ),
      ),
    );
  }
}
