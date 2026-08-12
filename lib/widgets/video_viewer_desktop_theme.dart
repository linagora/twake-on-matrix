import 'dart:typed_data';

import 'package:twake_chat/pages/image_viewer/media_viewer_app_bar_web.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/widgets/video_player.dart';
import 'package:twake_chat/widgets/video_viewer_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoViewerDesktopTheme extends StatelessWidget {
  const VideoViewerDesktopTheme({super.key, this.bytes, this.url, this.event})
    : assert(bytes != null || url != null, 'bytes or url must be provided');

  final Uint8List? bytes;

  final String? url;

  final Event? event;

  @override
  Widget build(BuildContext context) {
    return MaterialDesktopVideoControlsTheme(
      normal: MaterialDesktopVideoControlsThemeData(
        seekBarColor: Theme.of(context).colorScheme.onSurfaceVariant,
        seekBarPositionColor: Theme.of(context).colorScheme.primary,
        seekBarHeight: VideoViewerStyle.seekBarHeight,
        seekBarThumbColor: Theme.of(context).colorScheme.primary,
        topButtonBarMargin: const EdgeInsets.all(0),
        topButtonBar: [MediaViewerAppBarWeb(event: event)],
      ),
      fullscreen: MaterialDesktopVideoControlsThemeData(
        seekBarColor: Theme.of(context).colorScheme.onSurfaceVariant,
        seekBarPositionColor: Theme.of(context).colorScheme.primary,
        seekBarHeight: VideoViewerStyle.seekBarHeight,
        seekBarThumbColor: Theme.of(context).colorScheme.primary,
      ),
      child: VideoPlayer(bytes: bytes, url: url, mimeType: event?.mimeType),
    );
  }
}
