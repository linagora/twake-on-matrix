import 'package:fluffychat/pages/chat/events/image_bubble.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/presentation/enum/chat/media_viewer_popup_result_enum.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:matrix/matrix.dart';

class UnencryptedImageBuilderWeb extends StatelessWidget {
  final Event event;

  final bool isThumbnail;

  final double width;

  final double height;

  final BoxFit fit;

  final VoidCallback? closeRightColumn;

  final void Function()? onTapPreview;

  final void Function()? onTapSelectMode;

  const UnencryptedImageBuilderWeb({
    super.key,
    required this.event,
    this.isThumbnail = true,
    this.width = 256,
    this.height = 300,
    this.fit = BoxFit.cover,
    this.onTapSelectMode,
    this.onTapPreview,
    this.closeRightColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: event.eventId,
      child: Material(
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12.0),
          onTap: onTapPreview != null || onTapSelectMode != null
              ? () => _onTap(context)
              : null,
          child: UnencryptedImageWidget(
            event: event,
            isThumbnail: isThumbnail,
            width: width,
            height: height,
            fit: fit,
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) async {
    if (onTapPreview != null) {
      onTapPreview!();
      final result =
          await Navigator.of(context, rootNavigator: PlatformInfos.isWeb).push(
        HeroPageRoute(
          builder: (context) {
            return InteractiveViewerGallery(
              itemBuilder: ImageViewer(
                event: event,
              ),
            );
          },
        ),
      );
      if (result == MediaViewerPopupResultEnum.closeRightColumnFlag) {
        closeRightColumn?.call();
      }
    } else if (onTapSelectMode != null) {
      onTapSelectMode!();
      return;
    } else {
      return;
    }
  }
}

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
          duration: const Duration(milliseconds: 300),
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
      cacheWidth: (width * MediaQuery.of(context).devicePixelRatio).toInt(),
      filterQuality: FilterQuality.none,
      errorBuilder: (context, error, stackTrace) {
        return BlurHash(
          hash: event.blurHash ?? MessageContentStyle.defaultBlurHash,
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
