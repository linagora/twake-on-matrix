import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/video_viewer_dialog.dart';
import 'package:flutter/material.dart';

mixin PlayVideoActionMixin {
  void playVideoAction(BuildContext context, String uriOrFilePath) async {
    await showDialog(
      context: context,
      useRootNavigator: PlatformInfos.isWeb,
      useSafeArea: false,
      builder: (context) {
        return VideoViewerDialog(path: uriOrFilePath);
      },
    );
  }
}
