import 'dart:typed_data';

import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/video_player.dart';
import 'package:fluffychat/widgets/video_viewer_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoViewerMobileTheme extends StatefulWidget {
  const VideoViewerMobileTheme({super.key, this.bytes, this.url, this.event})
    : assert(bytes != null || url != null, 'bytes or url must be provided');

  final Uint8List? bytes;

  final String? url;

  final Event? event;

  @override
  State<VideoViewerMobileTheme> createState() => _VideoViewerMobileThemeState();
}

class _VideoViewerMobileThemeState extends State<VideoViewerMobileTheme> {
  late VideoPlayer player;

  @override
  void initState() {
    super.initState();
    player = VideoPlayer(bytes: widget.bytes, url: widget.url);
  }

  @override
  void didUpdateWidget(covariant VideoViewerMobileTheme oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bytes != widget.bytes || oldWidget.url != widget.url) {
      player = VideoPlayer(bytes: widget.bytes, url: widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialVideoControlsTheme(
      normal: MaterialVideoControlsThemeData(
        topButtonBarMargin: VideoViewerStyle.topButtonBarMargin(context),
        bottomButtonBar: const [MaterialPositionIndicator(), Spacer()],
        topButtonBar: [
          Expanded(
            child: MediaViewerAppBar(
              event: widget.event,
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
      child: widget.event != null
          ? Stack(
              alignment: Alignment.center,
              children: [
                MxcImage(event: widget.event),
                player,
              ],
            )
          : player,
    );
  }
}
