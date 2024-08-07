import 'package:fluffychat/pages/chat/events/event_video_player.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/presentation/model/chat/upload_file_ui_state.dart';
import 'package:fluffychat/widgets/mixins/upload_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

class MessageVideoUploadContentWeb extends StatefulWidget {
  const MessageVideoUploadContentWeb({
    super.key,
    required this.event,
    required this.width,
    required this.height,
  });

  final Event event;

  final double width;

  final double height;

  @override
  State<StatefulWidget> createState() => _MessageVideoUploadContentWebState();
}

class _MessageVideoUploadContentWebState
    extends State<MessageVideoUploadContentWeb>
    with UploadFileMixin<MessageVideoUploadContentWeb> {
  @override
  Event get event => widget.event;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: uploadFileStateNotifier,
      builder: ((context, uploadState, child) {
        double? progress;

        if (uploadState is UploadingFileUIState) {
          if (uploadState.total != null &&
              uploadState.receive != null &&
              uploadState.receive != 0) {
            progress = uploadState.receive! / uploadState.total!;
          }
        }
        return EventVideoPlayer(
          widget.event,
          width: widget.width,
          height: widget.height,
          onVideoTapped: () {
            if (uploadState is UploadFileSuccessUIState) {
              return;
            }
            uploadManager.cancelUpload(event);
          },
          centerWidget: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: MessageContentStyle.videoCenterButtonSize,
                height: MessageContentStyle.videoCenterButtonSize,
              ),
              if (uploadState is UploadFileSuccessUIState) ...[
                const SizedBox.shrink(),
              ] else
                const CenterVideoButton(
                  icon: Icons.close,
                  iconSize: MessageContentStyle.cancelButtonSize,
                ),
              SizedBox(
                width: MessageContentStyle.iconInsideVideoButtonSize,
                height: MessageContentStyle.iconInsideVideoButtonSize,
                child: CircularProgressIndicator(
                  value: uploadState is UploadingFileUIState ? progress : null,
                  color: LinagoraRefColors.material().primary[100],
                  strokeWidth: MessageContentStyle.strokeVideoWidth,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
