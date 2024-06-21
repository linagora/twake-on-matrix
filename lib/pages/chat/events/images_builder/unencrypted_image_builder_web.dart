import 'package:fluffychat/pages/chat/events/images_builder/image_placeholder.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_avif/flutter_avif.dart';

class UnencryptedImageWidget extends StatelessWidget {
  const UnencryptedImageWidget({
    super.key,
    required this.event,
    required this.isThumbnail,
    required this.width,
    required this.height,
    required this.fit,
  });

  final Event event;
  final bool isThumbnail;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (event.mimeType == TwakeMimeTypeExtension.avifMimeType) {
      return AvifImage.network(
        event
            .attachmentOrThumbnailMxcUrl(getThumbnail: isThumbnail)!
            .getDownloadLink(event.room.client)
            .toString(),
        height: height,
        width: width,
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      event
          .attachmentOrThumbnailMxcUrl(getThumbnail: isThumbnail)!
          .getDownloadLink(event.room.client)
          .toString(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedSwitcher(
          duration: MessageContentStyle.animationSwitcherDuration,
          child: frame != null
              ? child
              : ImagePlaceholder(
                  event: event,
                  width: width,
                  height: height,
                  fit: fit,
                ),
        );
      },
      fit: fit,
      width: width,
      height: height,
      cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
      cacheHeight: (height * MediaQuery.devicePixelRatioOf(context)).round(),
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: width,
              height: height,
              child: BlurHash(
                hash: event.blurHash ?? MessageContentStyle.defaultBlurHash,
              ),
            ),
            Icon(
              Icons.error,
              size: MessageContentStyle.iconErrorSize,
              color: Theme.of(context).colorScheme.onError,
            ),
          ],
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return SizedBox(
          width: width,
          height: height,
          child: BlurHash(
            hash: event.blurHash ?? MessageContentStyle.defaultBlurHash,
          ),
        );
      },
    );
  }
}
