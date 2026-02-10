import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/chat/upload_file_ui_state.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';
import 'package:fluffychat/widgets/mixins/upload_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class SendingVideoWidget extends StatefulWidget {
  final Event event;

  final MatrixVideoFile matrixFile;

  final DisplayImageInfo displayImageInfo;

  final double? bubbleWidth;

  const SendingVideoWidget({
    super.key,
    required this.event,
    required this.matrixFile,
    required this.displayImageInfo,
    this.bubbleWidth,
  });

  @override
  State<SendingVideoWidget> createState() => _SendingVideoWidgetState();
}

class _SendingVideoWidgetState extends State<SendingVideoWidget>
    with PlayVideoActionMixin, UploadFileMixin {
  @override
  Event get event => widget.event;

  late final VideoWidget videoWidget;

  @override
  void initState() {
    super.initState();
    videoWidget = VideoWidget(
      imageHeight: widget.displayImageInfo.size.height,
      imageWidth: widget.displayImageInfo.size.width,
      matrixFile: widget.matrixFile,
      event: event,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sysColor = LinagoraSysColors.material();
    return ClipRRect(
      borderRadius: MessageContentStyle.borderRadiusBubble,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: MessageStyle.mediaContentWidth(
              context: context,
              event: event,
              calculatedWidth:
                  MessageContentStyle.combinedBubbleImageWidthWithBubbleMaxWidget(
                    bubbleImageWidget: widget.displayImageInfo.size.width,
                    bubbleMaxWidth: widget.bubbleWidth ?? 0,
                  ),
            ),
            height: MessageContentStyle.imageBubbleHeight(
              widget.displayImageInfo.size.height,
            ),
            child: const BlurHash(hash: MessageContentStyle.defaultBlurHash),
          ),
          videoWidget,
          ...switch (event.status) {
            EventStatus.error => [
              IconButton(
                onPressed: () {
                  uploadManager.retryUpload(event);
                },
                icon: Icon(Icons.refresh, color: sysColor.primary, size: 24),
                padding: const EdgeInsets.all(4),
                style: IconButton.styleFrom(
                  backgroundColor: sysColor.onPrimary,
                  shape: const CircleBorder(),
                ),
              ),
            ],
            EventStatus.sent || EventStatus.synced => [
              InkWell(
                onTap: () => _onPlayVideo(context),
                child: const _PlayVideoButton(),
              ),
            ],
            _ => [
              _PlayVideoButton(event: event),
              ValueListenableBuilder(
                valueListenable: uploadFileStateNotifier,
                builder: (context, state, child) {
                  int? receive, total;
                  double? progress;
                  if (state is UploadingFileUIState) {
                    receive = state.receive;
                    total = state.total;
                  }
                  if (receive != null && total != null && total > 0) {
                    progress = receive / total;
                  }
                  return InkWell(
                    onTap: () {
                      if (state is UploadFileSuccessUIState) {
                        return;
                      }
                      uploadManager.cancelUpload(event);
                    },
                    child: SizedBox(
                      width: MessageContentStyle.videoCenterButtonSize,
                      height: MessageContentStyle.videoCenterButtonSize,
                      child: CircularProgressIndicator(
                        strokeWidth: MessageContentStyle.strokeVideoWidth,
                        color: LinagoraRefColors.material().primary[100],
                        value: progress,
                      ),
                    ),
                  );
                },
              ),
            ],
          },
        ],
      ),
    );
  }

  void _onPlayVideo(BuildContext context) async {
    playVideoAction(
      context,
      widget.matrixFile.bytes,
      event: event,
      isReplacement: false,
    );
  }
}

class VideoWidget extends StatelessWidget {
  const VideoWidget({
    super.key,
    required this.imageHeight,
    required this.imageWidth,
    required this.matrixFile,
    required this.event,
  });

  final double imageHeight;
  final double imageWidth;
  final MatrixVideoFile matrixFile;
  final Event event;

  @override
  Widget build(BuildContext context) {
    final placeholder = SizedBox(width: imageWidth, height: imageHeight);

    return FutureBuilder(
      future: event.room.generateVideoThumbnail(matrixFile),
      builder: (context, snapshot) {
        if (snapshot.data == null) return placeholder;

        return Image.memory(
          snapshot.data!.bytes,
          width: imageWidth,
          height: imageHeight,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }
}

class _PlayVideoButton extends StatelessWidget {
  final Event? event;

  const _PlayVideoButton({this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MessageContentStyle.videoCenterButtonSize,
      height: MessageContentStyle.videoCenterButtonSize,
      decoration: const BoxDecoration(
        color: Colors.black38,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        event != null ? Icons.close : Icons.play_arrow_rounded,
        color: LinagoraRefColors.material().primary[100],
        size: MessageContentStyle.iconInsideVideoButtonSize,
      ),
    );
  }
}

enum SendingVideoStatus { sending, sent, error }
