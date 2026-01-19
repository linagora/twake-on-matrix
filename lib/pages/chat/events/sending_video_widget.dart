import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/chat/upload_file_ui_state.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
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
  final sendingFileProgressNotifier = ValueNotifier(SendingVideoStatus.sending);

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
      event: widget.event,
    );
  }

  @override
  void dispose() {
    sendingFileProgressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _checkSendingFileStatus();

    return ValueListenableBuilder<SendingVideoStatus>(
      key: ValueKey(widget.event.eventId),
      valueListenable: sendingFileProgressNotifier,
      builder: ((context, value, _) {
        return ClipRRect(
          borderRadius: MessageContentStyle.borderRadiusBubble,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: widget.event.isReplyEvent()
                    ? double.infinity
                    : MessageContentStyle
                        .combinedBubbleImageWidthWithBubbleMaxWidget(
                        bubbleImageWidget: widget.displayImageInfo.size.width,
                        bubbleMaxWidth: widget.bubbleWidth ?? 0,
                      ),
                height: MessageContentStyle.imageBubbleHeight(
                  widget.displayImageInfo.size.height,
                ),
                child:
                    const BlurHash(hash: MessageContentStyle.defaultBlurHash),
              ),
              videoWidget,
              if (value == SendingVideoStatus.sending) ...[
                _PlayVideoButton(
                  event: widget.event,
                ),
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
                        uploadManager.cancelUpload(widget.event);
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
              ] else if (value == SendingVideoStatus.sent) ...[
                InkWell(
                  onTap: () => _onPlayVideo(context),
                  child: const _PlayVideoButton(),
                ),
              ] else if (value == SendingVideoStatus.error) ...[
                const SizedBox(
                  width: MessageContentStyle.videoCenterButtonSize,
                  height: MessageContentStyle.videoCenterButtonSize,
                  child: Icon(Icons.error),
                ),
              ],
            ],
          ),
        );
      }),
      child: Hero(
        tag: widget.event.eventId,
        child: VideoWidget(
          imageHeight: widget.displayImageInfo.size.height,
          imageWidth: widget.displayImageInfo.size.width,
          matrixFile: widget.matrixFile,
          event: widget.event,
        ),
      ),
    );
  }

  void _onPlayVideo(BuildContext context) async {
    playVideoAction(
      context,
      widget.matrixFile.bytes,
      event: widget.event,
      isReplacement: false,
    );
  }

  void _checkSendingFileStatus() {
    if ((widget.event.status == EventStatus.sent ||
            widget.event.status == EventStatus.synced) &&
        sendingFileProgressNotifier.value != SendingVideoStatus.sent) {
      sendingFileProgressNotifier.value = SendingVideoStatus.sent;
    } else if (widget.event.status == EventStatus.error) {
      sendingFileProgressNotifier.value = SendingVideoStatus.error;
    }
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

enum SendingVideoStatus {
  sending,
  sent,
  error,
}
