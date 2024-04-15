import 'dart:io';
import 'dart:typed_data';

import 'package:fluffychat/pages/image_viewer/image_viewer_style.dart';
import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'image_viewer.dart';

class ImageViewerView extends StatelessWidget {
  final ImageViewerController controller;
  final Uint8List? imageData;
  final String? filePath;

  const ImageViewerView(
    this.controller, {
    Key? key,
    this.imageData,
    this.filePath,
  }) : super(key: key);

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
      imageWidget = _ImageWidget(event: controller.widget.event!);
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
  final Event event;

  const _ImageWidget({required this.event});

  @override
  Widget build(BuildContext context) {
    if (PlatformInfos.isWeb) {
      return FutureBuilder(
        future: event.downloadAndDecryptAttachment(
          getThumbnail: true,
        ),
        builder: (context, snapshot) {
          if (snapshot.data == null || snapshot.data!.bytes?.isEmpty != false) {
            return const CircularProgressIndicator();
          }
          return Image.memory(snapshot.data!.bytes!);
        },
      );
    } else {
      return FutureBuilder(
        future: event.getFileInfo(
          getThumbnail: false,
        ),
        builder: (context, snapshot) {
          if (snapshot.data == null || snapshot.data!.fileName.isEmpty) {
            return const CircularProgressIndicator();
          }
          return Image.file(File(snapshot.data!.filePath));
        },
      );
    }
  }
}
