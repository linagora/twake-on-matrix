import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:twake_chat/pages/chat/events/download_video_widget.dart';
import 'package:twake_chat/pages/chat/events/event_video_player.dart';
import 'package:twake_chat/pages/chat_details/chat_details_page_view/media/chat_details_media_style.dart';
import 'package:twake_chat/pages/media_viewer/media_viewer.dart';
import 'package:twake_chat/presentation/same_type_events_builder/same_type_events_builder.dart';
import 'package:twake_chat/presentation/same_type_events_builder/same_type_events_controller.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/presentation/enum/chat/media_viewer_popup_result_enum.dart';
import 'package:twake_chat/utils/dismissible_media_view.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/hero_page_route.dart';

class ChatDetailsMediaPage extends StatelessWidget {
  final SameTypeEventsBuilderController controller;
  final Map<EventId, ImageData>? cacheMap;
  final DownloadVideoEventCallback handleDownloadVideoEvent;
  final VoidCallback? closeRightColumn;

  const ChatDetailsMediaPage({
    super.key,
    required this.controller,
    required this.handleDownloadVideoEvent,
    this.cacheMap,
    this.closeRightColumn,
  });

  @override
  Widget build(BuildContext context) {
    return SameTypeEventsBuilder(
      controller: controller,
      builder: (context, eventsState, _) {
        final events =
            eventsState
                .getSuccessOrNull<TimelineSearchEventSuccess>()
                ?.events ??
            [];
        Logs().v("ChatDetailsMediaPage::events: ${events.length}");
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ChatDetailsMediaStyle.crossAxisCount(context),
          ),
          itemCount: events.length,
          itemBuilder: (context, index) =>
              events[index].messageType == MessageTypes.Image
              ? _ImageItem(
                  event: events[index],
                  cacheMap: cacheMap,
                  closeRightColumn: closeRightColumn,
                )
              : _VideoItem(
                  event: events[index],
                  handleDownloadVideoEvent: handleDownloadVideoEvent,
                  thumbnailCacheMap: cacheMap,
                  closeRightColumn: closeRightColumn,
                ),
        );
      },
    );
  }
}

class _ImageItem extends StatelessWidget {
  final Event event;
  final Map<EventId, ImageData>? cacheMap;
  final VoidCallback? closeRightColumn;

  const _ImageItem({required this.event, this.cacheMap, this.closeRightColumn});

  @override
  Widget build(BuildContext context) {
    return MxcImage(
      event: event,
      isThumbnail: true,
      fit: BoxFit.cover,
      onTapPreview: () {},
      isPreview: true,
      placeholder: (context) =>
          BlurHash(hash: event.blurHash ?? AppConfig.defaultImageBlurHash),
      cacheKey: event.eventId,
      cacheMap: cacheMap,
      closeRightColumn: closeRightColumn,
    );
  }
}

class _VideoItem extends StatelessWidget {
  final Event event;
  final DownloadVideoEventCallback handleDownloadVideoEvent;
  final Map<EventId, ImageData>? thumbnailCacheMap;
  final VoidCallback? closeRightColumn;

  const _VideoItem({
    required this.event,
    required this.handleDownloadVideoEvent,
    this.thumbnailCacheMap,
    this.closeRightColumn,
  });

  static final responsiveUtil = getIt.get<ResponsiveUtils>();

  @override
  Widget build(BuildContext context) {
    final centerVideoWidget = !responsiveUtil.isDesktop(context)
        ? const CenterVideoButton(icon: Icons.play_arrow)
        : const SizedBox.shrink();
    return EventVideoPlayer(
      event,
      rounded: false,
      showDuration: true,
      thumbnailCacheKey: event.eventId,
      thumbnailCacheMap: thumbnailCacheMap,
      noResizeThumbnail: true,
      centerWidget: centerVideoWidget,
      onVideoTapped: () => _onTapVideo(context),
    );
  }

  Future<void> _onTapVideo(BuildContext context) async {
    final result =
        await Navigator.of(context, rootNavigator: PlatformInfos.isWeb).push(
          HeroPageRoute(
            builder: (context) {
              return DismissibleMediaView(
                itemBuilder: PlatformInfos.isMobile
                    ? MediaViewer(event: event)
                    : DownloadVideoWidget(event: event),
              );
            },
          ),
        );
    if (result == MediaViewerPopupResultEnum.closeRightColumnFlag) {
      closeRightColumn?.call();
    }
  }
}
