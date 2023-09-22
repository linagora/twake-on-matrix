import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:fluffychat/pages/chat/events/event_video_player.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/same_type_events_list_controller.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:matrix/matrix.dart';

class ChatDetailsMediaPage extends StatelessWidget {
  static const _mediaFetchLimit = 20;
  final Future<Timeline> Function() getTimeline;
  final Map<EventId, ImageData>? cacheMap;
  final DownloadVideoEventCallback handleDownloadVideoEvent;

  const ChatDetailsMediaPage({
    Key? key,
    required this.getTimeline,
    required this.handleDownloadVideoEvent,
    this.cacheMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SameTypeEventsListBuilder(
      getTimeline: getTimeline,
      searchFunc: (event) => event.isVideoOrImage,
      limit: _mediaFetchLimit,
      builder: (context, eventsState) {
        final events = eventsState
                .getSuccessOrNull<TimelineSearchEventSuccess>()
                ?.events ??
            [];
        Logs().v("ChatDetailsMediaPage::events: ${events.length}");
        return SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemCount: events.length,
          itemBuilder: (context, index) =>
              events[index].messageType == MessageTypes.Image
                  ? _ImageItem(
                      event: events[index],
                      cacheMap: cacheMap,
                    )
                  : _VideoItem(
                      event: events[index],
                      handleDownloadVideoEvent: handleDownloadVideoEvent,
                      thumbnailCacheMap: cacheMap,
                    ),
        );
      },
    );
  }
}

class _ImageItem extends StatelessWidget {
  final Event event;
  final Map<EventId, ImageData>? cacheMap;
  const _ImageItem({
    required this.event,
    this.cacheMap,
  });

  @override
  Widget build(BuildContext context) {
    return MxcImage(
      event: event,
      isThumbnail: true,
      fit: BoxFit.cover,
      onTapPreview: () {},
      isPreview: true,
      placeholder: (context) => BlurHash(
        hash: event.blurHash ?? AppConfig.defaultImageBlurHash,
      ),
      cacheKey: event.eventId,
      cacheMap: cacheMap,
    );
  }
}

class _VideoItem extends StatelessWidget {
  final Event event;
  final DownloadVideoEventCallback handleDownloadVideoEvent;
  final Map<EventId, ImageData>? thumbnailCacheMap;
  const _VideoItem({
    required this.event,
    required this.handleDownloadVideoEvent,
    this.thumbnailCacheMap,
  });

  @override
  Widget build(BuildContext context) {
    return EventVideoPlayer(
      event,
      handleDownloadVideoEvent: handleDownloadVideoEvent,
      rounded: false,
      showDuration: true,
      thumbnailCacheKey: event.eventId,
      thumbnailCacheMap: thumbnailCacheMap,
      noResizeThumbnail: true,
    );
  }
}
