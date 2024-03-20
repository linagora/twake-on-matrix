import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/video_player.dart';
import 'package:fluffychat/widgets/video_viewer_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoViewerMobileTheme extends StatelessWidget {
  const VideoViewerMobileTheme({
    super.key,
    required this.path,
    this.event,
  });

  final String path;

  final Event? event;

  @override
  Widget build(BuildContext context) {
    return MaterialVideoControlsTheme(
      normal: MaterialVideoControlsThemeData(
        topButtonBarMargin: VideoViewerStyle.topButtonBarMargin(context),
        bottomButtonBar: const [
          MaterialPositionIndicator(),
          Spacer(),
        ],
        topButtonBar: [
          Expanded(
            child: MediaViewerAppBar(
              event: event,
              enablePaddingAppbar: false,
            ),
          ),
        ],
        controlsHoverDuration: VideoViewerStyle.controlsHoverDuration,
        seekBarColor: Theme.of(context).colorScheme.onSurfaceVariant,
        seekBarPositionColor: Theme.of(context).colorScheme.primary,
        bottomButtonBarMargin: VideoViewerStyle.bottomBarMargin(context),
        seekBarMargin: VideoViewerStyle.bottomBarMargin(context),
        seekBarHeight: VideoViewerStyle.seekBarHeight,
        seekBarThumbColor: Theme.of(context).colorScheme.primary,
      ),
      fullscreen: const MaterialVideoControlsThemeData(),
      child: event != null
          ? Stack(
              alignment: Alignment.center,
              children: [
                MxcImage(event: event),
                VideoPlayer(
                  path: path,
                  event: event,
                ),
              ],
            )
          : VideoPlayer(
              path: path,
              event: event,
            ),
    );
  }
}
