import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:fluffychat/widgets/video_viewer_desktop_theme.dart';
import 'package:fluffychat/widgets/video_viewer_mobile_theme.dart';
import 'package:flutter/material.dart';

mixin PlayVideoActionMixin {
  void playVideoAction(
    BuildContext context,
    String uriOrFilePath, {
    String? eventId,
  }) async {
    Navigator.of(context, rootNavigator: PlatformInfos.isWeb).push(
      HeroPageRoute(
        builder: (context) {
          return InteractiveViewerGallery(
            itemBuilder: PlatformInfos.isMobile
                ? VideoViewerMobileTheme(
                    path: uriOrFilePath,
                    eventId: eventId,
                  )
                : VideoViewerDesktopTheme(path: uriOrFilePath),
          );
        },
      ),
    );
  }
}
