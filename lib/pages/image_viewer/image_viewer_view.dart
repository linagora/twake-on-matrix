import 'dart:io';
import 'dart:typed_data';

import 'package:fluffychat/pages/image_viewer/image_viewer_style.dart';
import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';

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
      imageWidget = MxcImage(
        event: controller.widget.event!,
        width: width,
        height: height,
        enableHeroAnimation: false,
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
      child: Center(child: imageWidget),
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
            } else if (controller.widget.showAppBar) {
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
