import 'dart:async';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/events/event_video_player.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/media_viewer/media_viewer.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:fluffychat/widgets/mixins/download_file_on_mobile_mixin.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class MessageVideoDownloadContent extends StatefulWidget {
  const MessageVideoDownloadContent({
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

  late final Completer<String?> _completer;
  Future<String?> getMobileThumbnail() async {
    try {
      final uploadFileInfo = await getIt.get<UploadManager>().getUploadFileInfo(
        event.eventId,
        room: event.room,
      );
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
    return FutureBuilder(
      future: _completer.future,
      builder: (context, asyncSnapshot) {
        return EventVideoPlayer(
          widget.event,
          width: widget.width,
          height: widget.height,
          bubbleWidth: widget.bubbleWidth,
          thumbnailPath: asyncSnapshot.data,
          centerWidget: ValueListenableBuilder(
            valueListenable: downloadFileStateNotifier,
            builder: (context, downloadState, child) {
              if (downloadState is DownloadingPresentationState) {
                double? progress;
                if (downloadState.total != null &&
                    downloadState.receive != null &&
                    downloadState.total! > 0) {
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
          onVideoTapped: () async {
            await Navigator.of(context).push(
              HeroPageRoute(
                builder: (context) {
                  return InteractiveViewerGallery(
                    itemBuilder: MediaViewer(event: event),
                  );
                },
              ),
            );
            if (!mounted) return;
            checkDownloadFileState();
          },
        );
      },
    );
  }
}
