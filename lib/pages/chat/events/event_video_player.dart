import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/download_video_state.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/media/chat_details_media_style.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat/events/image_bubble.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:linagora_design_flutter/extensions/duration_extension.dart';

typedef DownloadVideoEventCallback = Future<String> Function(Event event);

class EventVideoPlayer extends StatefulWidget {
  final Event event;

  final double? width;

  final double? height;

  final bool rounded;

  final bool showDuration;

  final DownloadVideoEventCallback? handleDownloadVideoEvent;

  final String? thumbnailCacheKey;

  final Map<EventId, ImageData>? thumbnailCacheMap;

  /// Enable it if the thumbnail image is stretched, and you don't want to resize it
  final bool noResizeThumbnail;

  const EventVideoPlayer(
    this.event, {
    Key? key,
    this.width,
    this.height,
    this.handleDownloadVideoEvent,
    this.rounded = true,
    this.showDuration = false,
    this.thumbnailCacheMap,
    this.thumbnailCacheKey,
    this.noResizeThumbnail = false,
  }) : super(key: key);

  @override
  EventVideoPlayerState createState() => EventVideoPlayerState();
}

class EventVideoPlayerState extends State<EventVideoPlayer>
    with PlayVideoActionMixin {
  final _downloadStateNotifier = ValueNotifier(DownloadVideoState.initial);
  String? path;

  void _downloadAction() async {
    _downloadStateNotifier.value = DownloadVideoState.loading;
    try {
      path = await widget.handleDownloadVideoEvent?.call(widget.event);
      _downloadStateNotifier.value = DownloadVideoState.done;
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

  @override
  Widget build(BuildContext context) {
    final hasThumbnail = widget.event.hasThumbnail;
    final blurHash = widget.event.blurHash ?? AppConfig.defaultVideoBlurHash;

    final width = widget.width ?? MessageContentStyle.imageWidth(context);
    final height = widget.height ?? MessageContentStyle.imageHeight(context);

    return ClipRRect(
      borderRadius: widget.rounded
          ? MessageContentStyle.borderRadiusBubble
          : BorderRadius.zero,
      child: Material(
        color: Colors.black,
        child: SizedBox(
          width: MessageContentStyle.imageBubbleWidth(width),
          height: MessageContentStyle.videoBubbleHeight(height),
          child: Stack(
            children: [
              const BlurHash(hash: AppConfig.defaultVideoBlurHash),
              if (hasThumbnail)
                Center(
                  child: ImageBubble(
                    widget.event,
                    tapToView: false,
                    width: MessageContentStyle.imageBubbleWidth(width),
                    height: MessageContentStyle.videoBubbleHeight(height),
                    rounded: widget.rounded,
                    thumbnailCacheKey: widget.thumbnailCacheKey,
                    thumbnailCacheMap: widget.thumbnailCacheMap,
                    noResizeThumbnail: widget.noResizeThumbnail,
                  ),
                )
              else
                BlurHash(hash: blurHash),
              Center(
                child: ValueListenableBuilder<DownloadVideoState>(
                  valueListenable: _downloadStateNotifier,
                  builder: (context, downloadState, child) {
                    switch (downloadState) {
                      case DownloadVideoState.loading:
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            _CenterVideoButton(
                              icon: Icons.play_arrow,
                              onTap: _downloadAction,
                            ),
                            SizedBox(
                              width: MessageContentStyle.videoCenterButtonSize,
                              height: MessageContentStyle.videoCenterButtonSize,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    LinagoraRefColors.material().primary[100],
                              ),
                            ),
                          ],
                        );
                      case DownloadVideoState.initial:
                        return _CenterVideoButton(
                          icon: Icons.play_arrow,
                          onTap: _downloadAction,
                        );
                      case DownloadVideoState.done:
                        return _CenterVideoButton(
                          icon: Icons.play_arrow,
                          onTap: () {
                            if (path != null) {
                              playVideoAction(
                                context,
                                path!,
                                eventId: widget.event.eventId,
                              );
                            }
                          },
                        );
                      case DownloadVideoState.failed:
                        return _CenterVideoButton(
                          icon: Icons.error,
                          onTap: _downloadAction,
                        );
                    }
                  },
                ),
              ),
              if (widget.showDuration)
                Positioned(
                  bottom: ChatDetailsMediaStyle.durationPosition,
                  right: ChatDetailsMediaStyle.durationPosition,
                  child: Container(
                    padding: ChatDetailsMediaStyle.durationPadding,
                    decoration: ChatDetailsMediaStyle.durationBoxDecoration(
                      context,
                    ),
                    child: Text(
                      widget.event.duration?.mediaTimeLength() ?? "--:--",
                      style: ChatDetailsMediaStyle.durationTextStyle(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterVideoButton extends StatelessWidget {
  final IconData icon;

  final VoidCallback? onTap;

  const _CenterVideoButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: MessageContentStyle.videoCenterButtonSize,
        height: MessageContentStyle.videoCenterButtonSize,
        decoration: const BoxDecoration(
          color: MessageContentStyle.backgroundColorCenterButton,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: LinagoraRefColors.material().primary[100],
          size: MessageContentStyle.iconInsideVideoButtonSize,
        ),
      ),
    );
  }
}
