import 'dart:io';
import 'dart:typed_data';

import 'package:fluffychat/pages/image_viewer/context_menu_item_image_viewer.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
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
              controller.toggleAppbarPreview();
            }
          },
          onDoubleTapDown: (details) => controller.onDoubleTapDown(details),
          onDoubleTap: () => controller.onDoubleTap(),
          child: Stack(
            children: [
              interactiveViewer,
              _buildAppBarPreview(),
            ],
          ),
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
                    controller.responsiveUtils.isMobile(context)
                        ? Icons.arrow_back_rounded
                        : Icons.close,
                    color: LinagoraSysColors.material().onPrimary,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  color: LinagoraSysColors.material().onPrimary,
                  tooltip: L10n.of(context)!.back,
                ),
                Row(
                  children: [
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
                    if (controller.widget.event != null)
                      IconButton(
                        icon: Icon(
                          Icons.shortcut,
                          color: LinagoraSysColors.material().onPrimary,
                        ),
                        onPressed: controller.forwardAction,
                        color: LinagoraSysColors.material().onPrimary,
                        tooltip: L10n.of(context)!.share,
                      ),
                    if (controller.widget.event != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: MenuAnchor(
                            controller: controller.menuController,
                            style: const MenuStyle(
                              alignment: Alignment.bottomRight,
                            ),
                            menuChildren: [
                              ContextMenuItemImageViewer(
                                icon: Icons.file_download_outlined,
                                title: L10n.of(context)!.saveFile,
                                onTap: () => controller.saveFileAction(),
                              ),
                              ContextMenuItemImageViewer(
                                title: L10n.of(context)!.showInChat,
                                imagePath: ImagePaths.icShowInChat,
                                onTap: () => controller.showInChat(),
                                haveDivider: false,
                              ),
                            ],
                            child: InkWell(
                              borderRadius: BorderRadius.circular(100),
                              onTap: () => controller.toggleShowMoreActions(),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TwakeIconButton(
                                  paddingAll: 0.0,
                                  icon: Icons.more_vert,
                                  iconColor:
                                      LinagoraSysColors.material().onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
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
