import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar_web.dart';
import 'package:fluffychat/widgets/video_player.dart';
import 'package:fluffychat/widgets/video_viewer_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoViewerDesktopTheme extends StatelessWidget {
  const VideoViewerDesktopTheme({
    super.key,
    required this.path,
    this.event,
  });

  final String path;

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
        topButtonBar: [
          MediaViewerAppBarWeb(event: event),
        ],
      ),
      fullscreen: MaterialDesktopVideoControlsThemeData(
        seekBarColor: Theme.of(context).colorScheme.onSurfaceVariant,
        seekBarPositionColor: Theme.of(context).colorScheme.primary,
        seekBarHeight: VideoViewerStyle.seekBarHeight,
        seekBarThumbColor: Theme.of(context).colorScheme.primary,
      ),
      child: VideoPlayer(
        path: path,
        event: event,
      ),
    );
  }
}
