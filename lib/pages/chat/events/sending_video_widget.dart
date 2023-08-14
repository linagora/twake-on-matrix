import 'dart:io';
import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:video_player/video_player.dart';

class SendingVideoWidget extends StatefulWidget {

  final Event event;

  final MatrixVideoFile matrixFile;

  const SendingVideoWidget({
    super.key,
    required this.event,
    required this.matrixFile,
  });

  @override
  State<SendingVideoWidget> createState() => _SendingVideoWidgetState();
}

class _SendingVideoWidgetState extends State<SendingVideoWidget> with AutomaticKeepAliveClientMixin {
  final sendingFileProgressNotifier = ValueNotifier(SendingVideoStatus.sending);
  ChewieController? chewieController;
  VideoPlayerController? videoPlayerController;

  bool isPlay = false;

  @override
  void dispose() {
    videoPlayerController?.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  Future<void> initVideoController() async {
    if (widget.matrixFile.filePath == null) {
      return ;
    }
    videoPlayerController = VideoPlayerController.file(
      File(widget.matrixFile.filePath!),
    );
    await videoPlayerController?.initialize();
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController!,
      autoPlay: false,
      showControlsOnInitialize: false,
      customControls: const MaterialControls(),
    );
    videoPlayerController!.addListener(() {
      if (!chewieController!.isPlaying && isPlay) {
        setState(() {
          isPlay = false;
        });
      } else if (chewieController!.isPlaying && isPlay == false) {
        setState(() {
          isPlay = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    /// FIXME: current time, the ticket focus on sending video, so i don't focus on
    /// video player, which is not have design, user story,
    /// so the solution for its working quite hard to read :))
    /// Sincerely sorry to person who read this code in the future.
    super.build(context);
    _checkSendingFileStatus();
    final (imageWidth, imageHeight) = _getImageSize(widget.matrixFile.width, widget.matrixFile.height);
    if (isPlay) {
      sendingFileProgressNotifier.value = SendingVideoStatus.playing;
    }
    
    return ValueListenableBuilder<SendingVideoStatus>(
      key: ValueKey(widget.event.eventId),
      valueListenable: sendingFileProgressNotifier, 
      builder: ((context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            child!,
            if (value == SendingVideoStatus.sending)... [
              Stack(
                alignment: Alignment.center,
                children: [
                  const _PlayVideoButton(),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: LinagoraRefColors.material().primary[100],
                    ),
                  ),
                ],
              ), 
            ] else if (value == SendingVideoStatus.sent)... [
              InkWell(
                onTap: _onPlayVideo,
                child: const _PlayVideoButton(),
              )
            ] else if (value == SendingVideoStatus.playing)... [
              const SizedBox(),
            ] else if (value == SendingVideoStatus.error) ... [
              const SizedBox(
                width: 56,
                height: 56,
                child: Icon(Icons.error),
              ),
            ]
          ],
        );
      }),
      child: VideoWidget(
        chewieController: chewieController, 
        imageHeight: imageHeight, 
        imageWidth: imageWidth,
        matrixFile: widget.matrixFile,
      ),
    );
  }

  (double, double) _getImageSize(int? imageWidth, int? imageHeight) {
    if (imageWidth == null || imageHeight == null) {
      return (MessageContentStyle.imageBubbleWidth, MessageContentStyle.imageBubbleHeight);
    }

    final ratio = MessageContentStyle.imageBubbleWidth / imageWidth;

    if (imageWidth <= imageHeight) {
      return (MessageContentStyle.imageBubbleWidth, MessageContentStyle.imageBubbleHeight);
    } else {
      return (MessageContentStyle.imageBubbleWidth, imageHeight * ratio);
    }
  }

  void _onPlayVideo() async {
    if (chewieController == null || videoPlayerController == null) {
      await initVideoController();
    }
    await chewieController?.play();
    sendingFileProgressNotifier.value = SendingVideoStatus.playing;
  }

  void _checkSendingFileStatus() {
    if (
      (widget.event.status == EventStatus.sent || widget.event.status == EventStatus.synced)
      && sendingFileProgressNotifier.value != SendingVideoStatus.sent
    ) {
      sendingFileProgressNotifier.value = SendingVideoStatus.sent;
    } else if (widget.event.status == EventStatus.error) {
      sendingFileProgressNotifier.value = SendingVideoStatus.error;
    }
  }
  
  @override
  bool get wantKeepAlive => true;
}

class VideoWidget extends StatelessWidget {
  const VideoWidget({
    super.key,
    required this.chewieController,
    required this.imageHeight,
    required this.imageWidth,
    required this.matrixFile,
  });

  final ChewieController? chewieController;
  final double imageHeight;
  final double imageWidth;
  final MatrixFile matrixFile;

  @override
  Widget build(BuildContext context) {
    return chewieController != null 
      ? SizedBox(
        height: imageHeight,
        width: imageWidth,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Material(
            color: Colors.black,
            child: Chewie(controller: chewieController!),
          ),
        ),
      )
      : ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.memory(
          matrixFile.bytes ?? Uint8List(0),
          width: imageWidth,
          height: imageHeight,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      );
  }
}

class _PlayVideoButton extends StatelessWidget {

  const _PlayVideoButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.black38,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.play_arrow_rounded,
        color: LinagoraRefColors.material().primary[100],
        size: 48,
      ),
    );
  }

}

enum SendingVideoStatus {
  sending, 
  sent,
  playing,
  error,
}