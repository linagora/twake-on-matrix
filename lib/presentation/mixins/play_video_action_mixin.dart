import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/video_viewer_desktop_theme.dart';
import 'package:fluffychat/widgets/video_viewer_mobile_theme.dart';
import 'package:flutter/material.dart';

mixin PlayVideoActionMixin {
  void playVideoAction(BuildContext context, String uriOrFilePath) async {
    await showDialog(
      context: context,
      useRootNavigator: PlatformInfos.isWeb,
      useSafeArea: false,
      builder: (context) {
        if (PlatformInfos.isWeb || PlatformInfos.isDesktop) {
          return VideoViewerDesktopTheme(path: uriOrFilePath);
        }
        return VideoViewerMobileTheme(path: uriOrFilePath);
      },
    );
  }
}
