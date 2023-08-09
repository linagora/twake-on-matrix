import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {},
            onDoubleTap: () => controller.toggleAppbarPreview(),
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 10.0,
              onInteractionEnd: controller.onInteractionEnds,
              child: Center(
                child: Hero(
                  tag: controller.widget.event.eventId,
                  child: filePath != null
                      ? Image.file(
                          File(filePath!),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        )
                      : MxcImage(
                          event: controller.widget.event,
                          fit: BoxFit.contain,
                          isThumbnail: false,
                          animated: false,
                          imageData: imageData,
                          isPreview: true,
                        ),
                ),
              ),
            ),
          ),
          _buildAppBarPreview(),
        ],
      ),
    );
  }

  Widget _buildAppBarPreview() {
    return Container(
      color: LinagoraSysColors.material().onTertiaryContainer.withOpacity(0.5),
      padding: const EdgeInsets.only(top: 56),
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
