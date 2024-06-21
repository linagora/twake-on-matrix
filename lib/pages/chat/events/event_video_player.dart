import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/media/chat_details_media_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat/events/images_builder/image_bubble.dart';
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

  final VoidCallback? onVideoTapped;

  final Widget centerWidget;

  const EventVideoPlayer(
    this.event, {
    super.key,
    this.width,
    this.height,
    this.rounded = true,
    this.showDuration = false,
    this.thumbnailCacheMap,
    this.thumbnailCacheKey,
    this.noResizeThumbnail = false,
    this.onVideoTapped,
    this.centerWidget = const CenterVideoButton(icon: Icons.play_arrow),
  });

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
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: () {
            if (onVideoTapped != null) {
              onVideoTapped!.call();
            }
          },
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
                      height:
                          MessageContentStyle.videoBubbleHeight(imageHeight),
                      rounded: rounded,
                      thumbnailCacheKey: thumbnailCacheKey,
                      thumbnailCacheMap: thumbnailCacheMap,
                      noResizeThumbnail: noResizeThumbnail,
                      thumbnailOnly: true,
                      isPreview: false,
                    ),
                  ),
                centerWidget,
                if (showDuration)
                  Positioned(
                    bottom: ChatDetailsMediaStyle.durationPaddingAll(context),
                    right: ChatDetailsMediaStyle.durationPaddingAll(context),
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
      ),
    );
  }
}

class CenterVideoButton extends StatelessWidget {
  final IconData icon;

  final double? iconSize;

  const CenterVideoButton({
    super.key,
    required this.icon,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        size: iconSize ?? MessageContentStyle.iconInsideVideoButtonSize,
      ),
    );
  }
}
