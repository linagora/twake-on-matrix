import 'dart:typed_data';

import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:fluffychat/widgets/video_viewer_desktop_theme.dart';
import 'package:fluffychat/widgets/video_viewer_mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin PlayVideoActionMixin {
  /// Navigates to the video viewer using in-memory [bytes] (web path).
  void playVideoAction(
    BuildContext context,
    Uint8List bytes, {
    Event? event,
    bool isReplacement = true,
  }) {
    _navigate(
      context,
      bytes: bytes,
      event: event,
      isReplacement: isReplacement,
    );
  }

  /// Navigates to the video viewer using a proxy [url] (mobile/desktop path).
  void playVideoActionByUrl(
    BuildContext context,
    String url, {
    Event? event,
    bool isReplacement = true,
  }) {
    _navigate(context, url: url, event: event, isReplacement: isReplacement);
  }

  void _navigate(
    BuildContext context, {
    Uint8List? bytes,
    String? url,
    Event? event,
    bool isReplacement = true,
  }) {
    final pageRoute = HeroPageRoute(
      builder: (context) {
        return InteractiveViewerGallery(
          itemBuilder: PlatformInfos.isMobile
              ? VideoViewerMobileTheme(bytes: bytes, url: url, event: event)
              : VideoViewerDesktopTheme(bytes: bytes, url: url, event: event),
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
