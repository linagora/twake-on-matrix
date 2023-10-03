import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_dialog_route.dart';
import 'package:fluffychat/widgets/video_viewer_desktop_theme.dart';
import 'package:fluffychat/widgets/video_viewer_mobile_theme.dart';
import 'package:flutter/material.dart';

mixin PlayVideoActionMixin {
  void playVideoAction(
    BuildContext context,
    String uriOrFilePath, {
    String? eventId,
  }) async {
    if (!PlatformInfos.isWeb) {
      Navigator.of(context).push(
        HeroDialogRoute(
          builder: (context) {
            return InteractiveviewerGallery(
              itemBuilder: VideoViewerMobileTheme(
                path: uriOrFilePath,
                eventId: eventId,
              ),
            );
          },
        ),
      );
    } else {
      await showDialog(
        context: context,
        useRootNavigator: PlatformInfos.isWeb,
        useSafeArea: false,
        builder: (context) {
          if (PlatformInfos.isWeb || PlatformInfos.isDesktop) {
            return VideoViewerDesktopTheme(path: uriOrFilePath);
          }
          return VideoViewerMobileTheme(path: uriOrFilePath, eventId: eventId);
        },
      );
    }
  }
}
