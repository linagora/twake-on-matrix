import 'package:fluffychat/pages/chat/events/event_video_player.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/extension/web_url_creation_extension.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/widgets/mixins/download_file_on_web_mixin.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

class MessageVideoDownloadContentWeb extends StatefulWidget {
  const MessageVideoDownloadContentWeb({
    super.key,
    required this.event,
    required this.width,
    required this.height,
  });

  final Event event;

  final double width;

  final double height;

  @override
  State<StatefulWidget> createState() => _MessageVideoDownloadContentWebState();
}

class _MessageVideoDownloadContentWebState
    extends State<MessageVideoDownloadContentWeb>
    with
        DownloadFileOnWebMixin<MessageVideoDownloadContentWeb>,
        PlayVideoActionMixin {
  @override
  Event get event => widget.event;

  @override
  void handleDownloadMatrixFileSuccessDone({
    required DownloadMatrixFileSuccessState success,
  }) {
    if (mounted) {
      downloadFileStateNotifier.value = FileWebDownloadedPresentationState(
        matrixFile: success.matrixFile,
      );
      downloadFileStateNotifier.dispose();
    }

    streamSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: downloadFileStateNotifier,
      builder: ((context, downloadState, child) {
        if (downloadState is DownloadingPresentationState) {
          double? progress;
          if (downloadState.total != null &&
              downloadState.receive != null &&
              downloadState.receive != 0) {
            progress = downloadState.receive! / downloadState.total!;
          }
          return EventVideoPlayer(
            widget.event,
            width: widget.width,
            height: widget.height,
            onVideoTapped: () {
              downloadManager.cancelDownload(widget.event.eventId);
            },
            centerWidget: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: MessageContentStyle.videoCenterButtonSize,
                  height: MessageContentStyle.videoCenterButtonSize,
                ),
                const CenterVideoButton(
                  icon: Icons.close,
                  iconSize: MessageContentStyle.cancelButtonSize,
                ),
                SizedBox(
                  width: MessageContentStyle.iconInsideVideoButtonSize,
                  height: MessageContentStyle.iconInsideVideoButtonSize,
                  child: CircularProgressIndicator(
                    value: progress,
                    color: LinagoraRefColors.material().primary[100],
                    strokeWidth: MessageContentStyle.strokeVideoWidth,
                  ),
                ),
              ],
            ),
          );
        } else if (downloadState is NotDownloadPresentationState) {
          return EventVideoPlayer(
            widget.event,
            width: widget.width,
            height: widget.height,
            onVideoTapped: () async {
              onDownloadFileTap();
            },
            centerWidget: const CenterVideoButton(
              icon: Icons.arrow_downward,
              iconSize: MessageContentStyle.downloadButtonSize,
            ),
          );
        }
        return EventVideoPlayer(
          widget.event,
          width: widget.width,
          height: widget.height,
          onVideoTapped: () async {
            if (downloadState is FileWebDownloadedPresentationState) {
              playVideoAction(
                context,
                downloadState.matrixFile.bytes!.toWebUrl(
                  mimeType: downloadState.matrixFile.mimeType,
                ),
                isReplacement: false,
              );
            }
          },
        );
      }),
    );
  }
}
