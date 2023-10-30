import 'package:fluffychat/pages/chat/events/download_video_state.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({
    super.key,
    this.event,
  });

  final Event? event;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer>
    with HandleVideoDownloadMixin {
  final VideoController videoController = VideoController(Player());
  final _downloadStateNotifier = ValueNotifier(DownloadVideoState.initial);
  String? path;

  @override
  void initState() {
    super.initState();
    _downloadAction();
  }

  @override
  void dispose() {
    super.dispose();
    videoController.player.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ValueListenableBuilder<DownloadVideoState>(
        valueListenable: _downloadStateNotifier,
        builder: (context, downloadState, child) {
          switch (downloadState) {
            case DownloadVideoState.loading:
              return const CircularProgressIndicator();
            case DownloadVideoState.initial:
              return const SizedBox();
            case DownloadVideoState.done:
              return _buildVideoPlayer();
            case DownloadVideoState.failed:
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _downloadAction,
              );
          }
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Video(
      fill: Colors.transparent,
      pauseUponEnteringBackgroundMode: true,
      resumeUponEnteringForegroundMode: true,
      controller: videoController,
    );
  }

  void _downloadAction() async {
    _downloadStateNotifier.value = DownloadVideoState.loading;
    try {
      path = await handleDownloadVideoEvent(
        event: widget.event!,
      );
      _downloadStateNotifier.value = DownloadVideoState.done;
      videoController.player.open(Media(path!));
    } on MatrixConnectionException catch (e) {
      _downloadStateNotifier.value = DownloadVideoState.failed;
      TwakeSnackBar.show(
        context,
        e.toLocalizedString(context),
      );
    } catch (e, s) {
      _downloadStateNotifier.value = DownloadVideoState.failed;
      TwakeSnackBar.show(
        context,
        e.toLocalizedString(context),
      );
      Logs().w('Error while playing video', e, s);
    }
  }
}
