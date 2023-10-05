import 'dart:io';
import 'dart:typed_data';

import 'package:fluffychat/pages/image_viewer/image_viewer_style.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

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
    return Center(
      child: GestureDetector(
        onTap: () => controller.toggleAppbarPreview(),
        onDoubleTapDown: (details) => controller.onDoubleTapDown(details),
        onDoubleTap: () => controller.onDoubleTap(),
        child: Stack(
          children: [
            Hero(
              tag: controller.widget.event.eventId,
              child: InteractiveViewer(
                onInteractionEnd: controller.onInteractionEnds,
                transformationController: controller.transformationController,
                minScale: ImageViewerStyle.minScaleInteractiveViewer,
                maxScale: ImageViewerStyle.maxScaleInteractiveViewer,
                child: Center(
                  child: filePath != null
                      ? Image.file(
                          File(filePath!),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        )
                      : FutureBuilder(
                          future: controller.widget.event
                              .downloadAndDecryptAttachment(
                            // FIXME: change to false after https://github.com/linagora/twake-on-matrix/issues/746
                            getThumbnail: true,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.data == null ||
                                snapshot.data!.bytes == null) {
                              return const CircularProgressIndicator();
                            }
                            return Image.memory(snapshot.data!.bytes!);
                          },
                        ),
                ),
              ),
            ),
            _buildAppBarPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarPreview() {
    return Container(
      padding: ImageViewerStyle.paddingTopAppBar,
      height: ImageViewerStyle.appBarHeight,
      color: LinagoraSysColors.material().onTertiaryContainer.withOpacity(0.5),
      child: ValueListenableBuilder<bool>(
        valueListenable: controller.showAppbarPreview,
        builder: (context, showAppbar, _) {
          if (showAppbar) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: LinagoraSysColors.material().onPrimary,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  color: LinagoraSysColors.material().onPrimary,
                  tooltip: L10n.of(context)!.close,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.save_alt,
                        color: LinagoraSysColors.material().onPrimary,
                      ),
                      onPressed: () => controller.saveFileAction(context),
                      color: LinagoraSysColors.material().onPrimary,
                      tooltip: L10n.of(context)!.saveFile,
                    ),
                    //FIXME: https://github.com/linagora/twake-on-matrix/issues/435
                    if (PlatformInfos.isMobile)
                      Builder(
                        builder: (context) => IconButton(
                          onPressed: () => controller.shareFileAction(context),
                          tooltip: L10n.of(context)!.share,
                          color: LinagoraSysColors.material().onPrimary,
                          icon: Icon(
                            Icons.share,
                            color: LinagoraSysColors.material().onPrimary,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.shortcut,
                        color: LinagoraSysColors.material().onPrimary,
                      ),
                      onPressed: controller.forwardAction,
                      color: LinagoraSysColors.material().onPrimary,
                      tooltip: L10n.of(context)!.share,
                    ),
                  ],
                ),
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
