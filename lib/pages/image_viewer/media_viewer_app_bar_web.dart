import 'package:fluffychat/presentation/mixins/media_viewer_app_bar_mixin.dart';
import 'package:fluffychat/presentation/mixins/save_file_to_twake_downloads_folder_mixin.dart';
import 'package:fluffychat/presentation/mixins/save_media_to_gallery_android_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer_style.dart';

import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar.dart';
import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar_style.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class MediaViewerAppBarWeb extends StatelessWidget
    with
        SaveFileToTwakeAndroidDownloadsFolderMixin,
        SaveMediaToGalleryAndroidMixin,
        MediaViewerAppBarMixin {
  final Event? event;

  MediaViewerAppBarWeb({super.key, this.event});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: MediaViewewAppbarStyle.opacityAnimationDuration,
      curve: Curves.easeIn,
      child: Container(
        padding: ImageViewerStyle.paddingTopAppBar,
        height: ImageViewerStyle.appBarHeight,
        width: MediaQuery.sizeOf(context).width,
        color: MediaViewewAppbarStyle.appBarBackgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                MediaViewerAppBar.responsiveUtils.isMobile(context)
                    ? Icons.chevron_left_outlined
                    : Icons.close,
                color: LinagoraSysColors.material().onPrimary,
              ),
              onPressed: () => onClose(
                context,
              ),
              color: LinagoraSysColors.material().onPrimary,
              tooltip: L10n.of(context)!.back,
            ),
            Row(
              children: [
                if (event != null)
                  IconButton(
                    icon: Icon(
                      Icons.shortcut,
                      color: LinagoraSysColors.material().onPrimary,
                    ),
                    onPressed: () => forwardAction(
                      context,
                      event,
                    ),
                    color: LinagoraSysColors.material().onPrimary,
                    tooltip: L10n.of(context)!.share,
                  ),
                if (event != null) ...[
                  IconButton(
                    icon: Icon(
                      Icons.file_download_outlined,
                      color: LinagoraSysColors.material().onPrimary,
                    ),
                    tooltip: L10n.of(context)!.saveFile,
                    onPressed: () => saveFileAction(
                      context,
                      event,
                    ),
                  ),
                  IconButton(
                    tooltip: L10n.of(context)!.showInChat,
                    icon: SvgPicture.asset(
                      ImagePaths.icShowInChat,
                      colorFilter: ColorFilter.mode(
                        LinagoraSysColors.material().onPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () => showInChat(
                      context,
                      event,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
