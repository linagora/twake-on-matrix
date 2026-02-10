import 'dart:typed_data';

import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:fluffychat/widgets/video_viewer_desktop_theme.dart';
import 'package:fluffychat/widgets/video_viewer_mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin PlayVideoActionMixin {
  void playVideoAction(
    BuildContext context,
    Uint8List bytes, {
    Event? event,
    bool isReplacement = true,
  }) async {
    final pageRoute = HeroPageRoute(
      builder: (context) {
        return InteractiveViewerGallery(
          itemBuilder: PlatformInfos.isMobile
              ? VideoViewerMobileTheme(bytes: bytes, event: event)
              : VideoViewerDesktopTheme(bytes: bytes, event: event),
        );
      },
    );
    if (isReplacement) {
      Navigator.of(
        context,
        rootNavigator: PlatformInfos.isWeb,
      ).pushReplacement(pageRoute);
    } else {
      Navigator.of(context, rootNavigator: PlatformInfos.isWeb).push(pageRoute);
    }
  }
}
