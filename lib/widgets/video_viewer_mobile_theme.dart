import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:fluffychat/widgets/video_player.dart';
import 'package:fluffychat/widgets/video_viewer_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
        topButtonBar: [
          TwakeIconButton(
            tooltip: L10n.of(context)!.back,
            icon: Icons.close,
            onTap: () => context.pop(),
            iconColor: Theme.of(context).colorScheme.surface,
          ),
        ],
        bottomButtonBar: const [
          MaterialPositionIndicator(),
          Spacer(),
        ],
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
                ),
              ],
            )
          : VideoPlayer(path: path),
    );
  }
}
