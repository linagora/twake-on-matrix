import 'dart:async';

import 'package:fluffychat/pages/chat/events/event_video_player.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/presentation/model/chat/upload_file_ui_state.dart';
import 'package:fluffychat/widgets/mixins/upload_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class MessageVideoUploadContentWeb extends StatefulWidget {
  const MessageVideoUploadContentWeb({
    super.key,
    required this.event,
    required this.width,
    required this.height,
    this.bubbleWidth,
  });

  final Event event;

  final double width;

  final double height;

  final double? bubbleWidth;

  @override
  State<StatefulWidget> createState() => _MessageVideoUploadContentWebState();
}

class _MessageVideoUploadContentWebState
    extends State<MessageVideoUploadContentWeb>
    with UploadFileMixin<MessageVideoUploadContentWeb> {
  @override
  Event get event => widget.event;

  late final Completer<String?> _completer;
  Future<String?> getMobileThumbnail() async {
    try {
      final uploadFileInfo =
          await uploadManager.getUploadFileInfo(event.eventId);
      if (uploadFileInfo == null) {
        _completer.complete(null);
        return null;
      }

      final filePath = uploadFileInfo.fileInfo?.filePath;
      if (filePath == null) {
        _completer.complete(null);
        return null;
      }

      final thumbnail = await VideoThumbnail.thumbnailFile(video: filePath);
      _completer.complete(thumbnail.path);
      return thumbnail.path;
    } catch (e) {
      Logs().e('Error getting thumbnail: $e');
      _completer.complete(null);
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _completer = Completer<String?>();
    getMobileThumbnail();
  }

  @override
  Widget build(BuildContext context) {
    final sysColor = LinagoraSysColors.material();

    return ValueListenableBuilder(
      valueListenable: uploadFileStateNotifier,
      builder: ((context, uploadState, child) {
        double? progress;
        final hasError = uploadState is UploadFileFailedUIState;

        if (uploadState is UploadingFileUIState) {
          if (uploadState.total != null &&
              uploadState.receive != null &&
              uploadState.receive != 0) {
            progress = uploadState.receive! / uploadState.total!;
          }
        }
        return FutureBuilder(
          future: _completer.future,
          builder: (context, asyncSnapshot) {
            return EventVideoPlayer(
              widget.event,
              width: widget.width,
              height: widget.height,
              bubbleWidth: widget.bubbleWidth,
              thumbnailPath: asyncSnapshot.data,
              onVideoTapped: () {
                if (uploadState is UploadFileSuccessUIState) {
                  return;
                }
                if (hasError) {
                  uploadManager.retryUpload(event);
                } else {
                  uploadManager.cancelUpload(event);
                }
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
                  ] else if (hasError)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: sysColor.primary,
                        size: 24,
                      ),
                    )
                  else
                    const CenterVideoButton(
                      icon: Icons.close,
                      iconSize: MessageContentStyle.cancelButtonSize,
                    ),
                  if (!hasError)
                    SizedBox(
                      width: MessageContentStyle.iconInsideVideoButtonSize,
                      height: MessageContentStyle.iconInsideVideoButtonSize,
                      child: CircularProgressIndicator(
                        value: uploadState is UploadingFileUIState
                            ? progress
                            : null,
                        color: LinagoraRefColors.material().primary[100],
                        strokeWidth: MessageContentStyle.strokeVideoWidth,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
