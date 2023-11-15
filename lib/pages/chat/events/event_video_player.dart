import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/download_video_widget.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/media/chat_details_media_style.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat/events/image_bubble.dart';
import 'package:linagora_design_flutter/extensions/duration_extension.dart';

typedef DownloadVideoEventCallback = Future<String> Function(Event event);

class EventVideoPlayer extends StatelessWidget {
  final Event event;

  final double? width;

  final double? height;

  final bool rounded;

  final bool showDuration;

  final String? thumbnailCacheKey;

  final Map<EventId, ImageData>? thumbnailCacheMap;

  /// Enable it if the thumbnail image is stretched, and you don't want to resize it
  final bool noResizeThumbnail;

  const EventVideoPlayer(
    this.event, {
    Key? key,
    this.width,
    this.height,
    this.rounded = true,
    this.showDuration = false,
    this.thumbnailCacheMap,
    this.thumbnailCacheKey,
    this.noResizeThumbnail = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasThumbnail = event.hasThumbnail;
    final blurHash = event.blurHash ?? AppConfig.defaultVideoBlurHash;

    final imageWidth = width ?? MessageContentStyle.imageWidth(context);
    final imageHeight = height ?? MessageContentStyle.imageHeight(context);

    return ClipRRect(
      borderRadius:
          rounded ? MessageContentStyle.borderRadiusBubble : BorderRadius.zero,
      child: Material(
        color: Colors.black,
        child: SizedBox(
          width: MessageContentStyle.imageBubbleWidth(imageWidth),
          height: MessageContentStyle.videoBubbleHeight(imageHeight),
          child: Stack(
            alignment: Alignment.center,
            children: [
              BlurHash(hash: blurHash),
              if (hasThumbnail)
                Center(
                  child: ImageBubble(
                    event,
                    width: MessageContentStyle.imageBubbleWidth(imageWidth),
                    height: MessageContentStyle.videoBubbleHeight(imageHeight),
                    rounded: rounded,
                    thumbnailCacheKey: thumbnailCacheKey,
                    thumbnailCacheMap: thumbnailCacheMap,
                    noResizeThumbnail: noResizeThumbnail,
                    thumbnailOnly: true,
                  ),
                ),
              CenterVideoButton(
                icon: Icons.play_arrow,
                onTap: () async {
                  await Navigator.of(
                    context,
                    rootNavigator: PlatformInfos.isWeb,
                  ).push(
                    HeroPageRoute(
                      builder: (context) {
                        return InteractiveViewerGallery(
                          itemBuilder: Hero(
                            tag: event.eventId,
                            child: DownloadVideoWidget(event: event),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              if (showDuration)
                Positioned(
                  bottom: ChatDetailsMediaStyle.durationPosition,
                  right: ChatDetailsMediaStyle.durationPosition,
                  child: Container(
                    padding: ChatDetailsMediaStyle.durationPadding,
                    decoration: ChatDetailsMediaStyle.durationBoxDecoration(
                      context,
                    ),
                    child: Text(
                      event.duration?.mediaTimeLength() ?? "--:--",
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

class CenterVideoButton extends StatelessWidget {
  final IconData icon;

  final VoidCallback? onTap;

  const CenterVideoButton({
    super.key,
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
