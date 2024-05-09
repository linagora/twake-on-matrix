import 'package:fluffychat/pages/chat/events/event_video_player.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/widgets/mixins/download_file_on_mobile_mixin.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

class MessageVideoDownloadContent extends StatefulWidget {
  const MessageVideoDownloadContent({
    super.key,
    required this.event,
    required this.width,
    required this.height,
  });

  final Event event;

  final double width;

  final double height;

  @override
  State<StatefulWidget> createState() => _MessageVideoDownloadContentState();
}

class _MessageVideoDownloadContentState
    extends State<MessageVideoDownloadContent>
    with
        DownloadFileOnMobileMixin<MessageVideoDownloadContent>,
        PlayVideoActionMixin {
  @override
  Event get event => widget.event;

  @override
  void onDownloadedFileDone(String filePath) {
    super.onDownloadedFileDone(filePath);
    streamSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return EventVideoPlayer(
      widget.event,
      width: widget.width,
      height: widget.height,
      centerWidget: ValueListenableBuilder(
        valueListenable: downloadFileStateNotifier,
        builder: (context, downloadState, child) {
          if (downloadState is DownloadingPresentationState) {
            double? progress;
            if (downloadState.total != null && downloadState.total! > 0) {
              progress = downloadState.receive! / downloadState.total!;
            }
            return Stack(
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
            );
          } else if (downloadState is NotDownloadPresentationState) {
            return const CenterVideoButton(
              icon: Icons.arrow_downward,
              iconSize: MessageContentStyle.downloadButtonSize,
            );
          }
          return const CenterVideoButton(icon: Icons.play_arrow);
        },
      ),
      onVideoTapped: () {
        final downloadState = downloadFileStateNotifier.value;
        if (downloadState is DownloadingPresentationState) {
          downloadManager.cancelDownload(widget.event.eventId);
        } else if (downloadState is NotDownloadPresentationState) {
          onDownloadFileTap();
        } else if (downloadState is DownloadedPresentationState) {
          playVideoAction(
            context,
            downloadState.filePath,
            isReplacement: false,
          );
        }
      },
    );
  }
}
