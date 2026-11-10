import 'dart:typed_data';

import 'package:twake_chat/utils/extension/build_context_extension.dart';
import 'package:twake_chat/pages/chat/events/images_builder/image_builder_web.dart';
import 'package:twake_chat/pages/chat/events/images_builder/image_placeholder.dart';
import 'package:twake_chat/pages/chat/events/message_content_style.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.provider.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/widgets/mxc_image.dart';

class ImageBubble extends StatelessWidget {
  final Event event;
  final BoxFit fit;
  final bool maxSize;
  final bool thumbnailOnly;
  final bool animated;
  final double width;
  final double height;
  final double? bubbleMaxWidth;
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
    this.bubbleMaxWidth,
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
    final bubbleHeight = MessageContentStyle.imageBubbleHeight(height);
    const bubbleMinWidth = MessageContentStyle.imageBubbleMinWidth;
    final maxWidth =
        MessageContentStyle.combinedBubbleImageWidthWithBubbleMaxWidget(
          bubbleImageWidget: bubbleWidth,
          bubbleMaxWidth: bubbleMaxWidth ?? 0,
        );
    return Container(
      decoration: BoxDecoration(
        borderRadius: rounded
            ? MessageContentStyle.borderRadiusBubble
            : BorderRadius.zero,
      ),
      constraints: maxSize
          ? BoxConstraints(
              maxWidth: maxWidth,
              minWidth: bubbleMinWidth,
              maxHeight: bubbleHeight,
            )
          : null,
      child: ClipRRect(
        borderRadius: rounded
            ? MessageContentStyle.borderRadiusBubble
            : BorderRadius.zero,
        child:
            (PlatformInfos.isWeb &&
                !event.isBubbleEventEncrypted(isThumbnail: thumbnailOnly))
            ? UnencryptedImageBuilderWeb(
                event: event,
                bubbleMaxWidth: bubbleMaxWidth,
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
                    width: maxWidth,
                    height: bubbleHeight,
                    child: BlurHash(
                      hash:
                          event.blurHash ?? MessageContentStyle.defaultBlurHash,
                    ),
                  ),
                  MxcImage(
                    event: event,
                    width: width,
                    height: height,
                    cacheWidth: noResizeThumbnail
                        ? null
                        : context.getCacheSize(width),
                    cacheHeight: noResizeThumbnail
                        ? null
                        : context.getCacheSize(height),
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

/// An album image that is still uploading: shows the local picture with a spinner
/// on top. A failed image leaves the album (see `GroupMediaEventsPolicy`) and
/// gets the retry of a single image bubble.
class PendingImageTile extends ConsumerStatefulWidget {
  final Event event;

  const PendingImageTile({super.key, required this.event});

  @override
  ConsumerState<PendingImageTile> createState() => PendingImageTileState();
}

class PendingImageTileState extends ConsumerState<PendingImageTile> {
  late Future<MatrixFile?> _file;

  @override
  void initState() {
    super.initState();
    _file = widget.event.getPlaceholderMatrixFile(
      ref.read(uploadManagerProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.event.filename,
      image: true,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          BlurHash(
            hash: widget.event.blurHash ?? MessageContentStyle.defaultBlurHash,
          ),
          FutureBuilder<MatrixFile?>(
            future: _file,
            builder: (context, snapshot) {
              final bytes = snapshot.data?.bytes;
              if (bytes == null || bytes.isEmpty) {
                return const SizedBox.shrink();
              }
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                cacheWidth: context.getCacheSize(256),
                filterQuality: FilterQuality.none,
              );
            },
          ),
          ColoredBox(color: Colors.black.withAlpha(40)),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
