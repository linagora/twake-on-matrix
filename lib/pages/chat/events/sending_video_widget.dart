import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class SendingVideoWidget extends StatelessWidget with PlayVideoActionMixin {
  final Event event;

  final MatrixVideoFile matrixFile;

  final DisplayImageInfo displayImageInfo;

  SendingVideoWidget({
    super.key,
    required this.event,
    required this.matrixFile,
    required this.displayImageInfo,
  });

  final sendingFileProgressNotifier = ValueNotifier(SendingVideoStatus.sending);

  @override
  Widget build(BuildContext context) {
    _checkSendingFileStatus();

    return ValueListenableBuilder<SendingVideoStatus>(
      key: ValueKey(event.eventId),
      valueListenable: sendingFileProgressNotifier,
      builder: ((context, value, child) {
        return ClipRRect(
          borderRadius: MessageContentStyle.borderRadiusBubble,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: MessageContentStyle.imageBubbleWidth(
                  displayImageInfo.size.width,
                ),
                height: MessageContentStyle.imageBubbleHeight(
                  displayImageInfo.size.height,
                ),
                child:
                    const BlurHash(hash: MessageContentStyle.defaultBlurHash),
              ),
              child!,
              if (value == SendingVideoStatus.sending) ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const _PlayVideoButton(),
                    SizedBox(
                      width: MessageContentStyle.videoCenterButtonSize,
                      height: MessageContentStyle.videoCenterButtonSize,
                      child: CircularProgressIndicator(
                        strokeWidth: MessageContentStyle.strokeVideoWidth,
                        color: LinagoraRefColors.material().primary[100],
                      ),
                    ),
                  ],
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
        tag: event.eventId,
        child: VideoWidget(
          imageHeight: displayImageInfo.size.height,
          imageWidth: displayImageInfo.size.width,
          matrixFile: matrixFile,
          event: event,
        ),
      ),
    );
  }

  void _onPlayVideo(BuildContext context) async {
    if (matrixFile.filePath == null) {
      return;
    }
    playVideoAction(
      context,
      matrixFile.filePath!,
      event: event,
      isReplacement: false,
    );
  }

  void _checkSendingFileStatus() {
    if ((event.status == EventStatus.sent ||
            event.status == EventStatus.synced) &&
        sendingFileProgressNotifier.value != SendingVideoStatus.sent) {
      sendingFileProgressNotifier.value = SendingVideoStatus.sent;
    } else if (event.status == EventStatus.error) {
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
  final MatrixFile matrixFile;
  final Event event;

  @override
  Widget build(BuildContext context) {
    return matrixFile.bytes != null && matrixFile.bytes!.isNotEmpty
        ? Image.memory(
            matrixFile.bytes!,
            width: imageWidth,
            height: imageHeight,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          )
        : SizedBox(width: imageWidth, height: imageHeight);
  }
}

class _PlayVideoButton extends StatelessWidget {
  const _PlayVideoButton();

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
        Icons.play_arrow_rounded,
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
