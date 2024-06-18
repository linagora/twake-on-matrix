import 'dart:io';
import 'dart:typed_data';

import 'package:fluffychat/pages/image_viewer/image_viewer_style.dart';
import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:matrix/matrix.dart';

import 'image_viewer.dart';

class ImageViewerView extends StatelessWidget {
  final ImageViewerController controller;
  final Uint8List? imageData;
  final String? filePath;
  final double? width;
  final double? height;

  const ImageViewerView(
    this.controller, {
    super.key,
    this.imageData,
    this.filePath,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (filePath != null) {
      imageWidget = Image.file(
        File(filePath!),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      );
    } else if (controller.widget.event != null) {
      imageWidget = _ImageWidget(
        event: controller.widget.event!,
        controller: controller,
        width: width,
        height: height,
      );
    } else if (imageData != null) {
      imageWidget = Image.memory(
        imageData!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      );
    } else {
      return const SizedBox.shrink();
    }

    Widget interactiveViewer = InteractiveViewer(
      onInteractionEnd: controller.onInteractionEnds,
      transformationController: controller.transformationController,
      minScale: ImageViewerStyle.minScaleInteractiveViewer,
      maxScale: ImageViewerStyle.maxScaleInteractiveViewer,
      child: Center(
        child: imageWidget,
      ),
    );

    if (controller.widget.event != null) {
      interactiveViewer = Hero(
        tag: controller.widget.event!.eventId,
        child: interactiveViewer,
      );
    }

    return Center(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            if (PlatformInfos.isWeb) {
              Navigator.of(context).pop();
            } else {
              controller.showAppbarPreview.toggle();
            }
          },
          onDoubleTapDown: (details) => controller.onDoubleTapDown(details),
          onDoubleTap: () => controller.onDoubleTap(),
          child: Stack(
            children: [
              interactiveViewer,
              MediaViewerAppBar(
                showAppbarPreviewNotifier: controller.showAppbarPreview,
                event: controller.widget.event,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageWidget extends StatelessWidget {
  final ImageViewerController controller;

  final Event event;

  final double? width;

  final double? height;

  const _ImageWidget({
    required this.event,
    required this.controller,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformInfos.isWeb) {
      if (event.mimeType == TwakeMimeTypeExtension.avifMimeType) {
        return AvifImage.network(
          event
              .attachmentOrThumbnailMxcUrl()!
              .getDownloadLink(event.room.client)
              .toString(),
          height: height,
          width: width,
          fit: BoxFit.cover,
        );
      }
      return FutureBuilder(
        future: event.downloadAndDecryptAttachment(
          getThumbnail: true,
        ),
        builder: (context, snapshot) {
          if (snapshot.data == null || snapshot.data!.bytes?.isEmpty != false) {
            return const CircularProgressIndicator();
          }
          return Image.memory(
            snapshot.data!.bytes!,
            cacheWidth: width != null
                ? (width! * MediaQuery.devicePixelRatioOf(context)).toInt()
                : null,
          );
        },
      );
    } else {
      if (controller.filePath != null) {
        if (event.mimeType == TwakeMimeTypeExtension.avifMimeType) {
          return AvifImage.file(
            File(controller.filePath!),
            height: height,
            width: width,
            fit: BoxFit.cover,
          );
        }
        return Image.file(
          File(controller.filePath!),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (context, error, stackTrace) {
            return Image.file(
              File(controller.thumbnailFilePath!),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            );
          },
        );
      } else {
        return const CupertinoActivityIndicator(
          animating: true,
          color: Colors.white,
        );
      }
    }
  }
}
