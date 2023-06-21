import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/widgets/mxc_image.dart';

class ImageBubble extends StatefulWidget {
  final Event event;
  final bool tapToView;
  final BoxFit fit;
  final bool maxSize;
  final Color? backgroundColor;
  final bool thumbnailOnly;
  final bool animated;
  final double width;
  final double height;
  final void Function()? onTapPreview;
  final void Function()? onTapSelectMode;

  const ImageBubble(
    this.event, {
    this.tapToView = true,
    this.maxSize = true,
    this.backgroundColor,
    this.fit = BoxFit.cover,
    this.thumbnailOnly = true,
    this.width = 256,
    this.height = 300,
    this.animated = false,
    this.onTapSelectMode,
    this.onTapPreview,
    Key? key,
  }) : super(key: key);

  @override
  State<ImageBubble> createState() => _ImageBubbleState();
}

class _ImageBubbleState extends State<ImageBubble> {

  Uint8List? _imageDataCached;

  Widget _buildPlaceholder(BuildContext context) {
    if (widget.event.messageType == MessageTypes.Sticker) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }
    final String blurHashString =
        widget.event.infoMap['xyz.amorgan.blurhash'] is String
            ? widget.event.infoMap['xyz.amorgan.blurhash']
            : 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
    final ratio = widget.event.infoMap['w'] is int && widget.event.infoMap['h'] is int
        ? widget.event.infoMap['w'] / widget.event.infoMap['h']
        : 1.0;
    var width = 32;
    var height = 32;
    if (ratio > 1.0) {
      height = (width / ratio).round();
    } else {
      width = (height * ratio).round();
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: BlurHash(
        hash: blurHashString,
        decodingWidth: width,
        decodingHeight: height,
        imageFit: widget.fit,
      ),
    );
  }

  void _onTap(BuildContext context) async {
    if (widget.onTapPreview != null) {
      widget.onTapPreview!();
    } else {
      widget.onTapSelectMode!();
      return;
    }
    if (!widget.tapToView) return;
    await showGeneralDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, animationOne, animationTwo) =>
        ImageViewer(widget.event, imageData: _imageDataCached)
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onTap(context),
      child: Hero(
        tag: widget.event.eventId,
        child: AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20)
            ),
            constraints: widget.maxSize
                ? BoxConstraints(
                    maxWidth: widget.width,
                    maxHeight: widget.height,
                  )
                : null,
            child: MxcImage(
              rounded: true,
              event: widget.event,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              animated: widget.animated,
              isThumbnail: widget.thumbnailOnly,
              placeholder: _buildPlaceholder,
              callbackImage: (image) {
                _imageDataCached = image;
              },
            ),
          ),
        ),
      ),
    );
  }
}
