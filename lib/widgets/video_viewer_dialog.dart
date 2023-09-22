import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:fluffychat/widgets/video_viewer_dialog_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoViewerDialog extends StatefulWidget {
  const VideoViewerDialog({
    super.key,
    required this.path,
  });

  final String path;

  @override
  State<VideoViewerDialog> createState() => _VideoViewerDialogState();
}

class _VideoViewerDialogState extends State<VideoViewerDialog> {
  Player? videoPlayer;
  VideoController? videoController;
  bool isFullScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await initVideoController();
    });
  }

  Future<void> initVideoController() async {
    videoPlayer = Player();
    await videoPlayer?.open(Media(widget.path));
    if (videoPlayer == null) {
      Logs().e(
        'VideoViewerDialog::initVideoController(): video player open failed.',
      );
      context.pop();
    }
    videoController = VideoController(videoPlayer!);
    setState(() {
      videoPlayer!.play();
    });
  }

  @override
  void dispose() {
    videoPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialVideoControlsTheme(
      normal: MaterialVideoControlsThemeData(
        topButtonBarMargin: VideoViewerDialogStyle.topButtonBarMargin,
        topButtonBar: [
          Padding(
            padding: VideoViewerDialogStyle.topButtonPadding,
            child: TwakeIconButton(
              tooltip: L10n.of(context)!.back,
              icon: Icons.close,
              onTap: () => context.pop(),
              iconColor: Theme.of(context).colorScheme.surface,
            ),
          )
        ],
        bottomButtonBar: const [MaterialPositionIndicator(), Spacer()],
      ),
      fullscreen: MaterialVideoControlsThemeData(
        topButtonBar: [
          TwakeIconButton(
            tooltip: L10n.of(context)!.back,
            icon: Icons.close,
            onTap: () {
              context.pop();
            },
            iconColor: MessageContentStyle.backIconColor,
          )
        ],
      ),
      child: videoController != null
          ? Container(
              decoration: const BoxDecoration(
                color: MessageContentStyle.backgroundColorVideo,
              ),
              padding: VideoViewerDialogStyle.bottomPaddingVideo,
              child: SafeArea(
                child: Video(
                  pauseUponEnteringBackgroundMode: true,
                  resumeUponEnteringForegroundMode: true,
                  controls: MaterialVideoControls,
                  controller: videoController!,
                ),
              ),
            )
          : const SizedBox(),
    );
  }
}
