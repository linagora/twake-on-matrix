import 'package:fluffychat/pages/chat/events/images_builder/unencrypted_image_builder_web.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/presentation/enum/chat/media_viewer_popup_result_enum.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:flutter/material.dart';
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
    this.width = MessageContentStyle.imageBubbleWidthForMobileAndTablet,
    this.height = MessageContentStyle.imageBubbleHeightForMobileAndTable,
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
          borderRadius: MessageContentStyle.borderRadiusBubble,
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
    }
  }
}
