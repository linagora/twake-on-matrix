import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'image_viewer.dart';

class ImageViewerView extends StatelessWidget {
  final ImageViewerController controller;
  final Uint8List? imageData;

  const ImageViewerView(this.controller, {Key? key, this.imageData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBarPreview(),
      body: GestureDetector(
        onTap: () {},
        onDoubleTap: () => controller.toggleAppbarPreview(),
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 10.0,
          onInteractionEnd: controller.onInteractionEnds,
          child: Center(
            child: Hero(
              tag: controller.widget.event.eventId,
              child: MxcImage(
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
    );
  }

  PreferredSize _buildAppBarPreview() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ValueListenableBuilder<bool>(
        valueListenable: controller.showAppbarPreview,
        builder: (context, showAppbar, _) {
          if (showAppbar) {
            return AppBar(
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                onPressed: Navigator.of(context).pop,
                color: Theme.of(context).colorScheme.onSurface,
                tooltip: L10n.of(context)!.close,
              ),
              surfaceTintColor: Colors.transparent,
              actions: [
                if (PlatformInfos.isMobile)
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => controller.shareFileAction(context),
                      tooltip: L10n.of(context)!.share,
                      color: Theme.of(context).colorScheme.onSurface,
                      icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface,),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.shortcut, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: controller.forwardAction,
                  color: Theme.of(context).colorScheme.onSurface,
                  tooltip: L10n.of(context)!.share,
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
