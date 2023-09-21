import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/media/chat_details_media_style.dart';
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
  const ChatDetailsMediaPage({
    Key? key,
    required this.getTimeline,
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
          itemBuilder: (context, index) => Stack(
            fit: StackFit.expand,
            children: [
              MxcImage(
                event: events[index],
                isThumbnail: true,
                fit: BoxFit.cover,
                onTapPreview: () {},
                isPreview: true,
                placeholder: (context) => BlurHash(
                  hash:
                      events[index].blurHash ?? AppConfig.defaultImageBlurHash,
                ),
                cacheKey: events[index].eventId,
                cacheMap: cacheMap,
              ),
              if (events[index].messageType == MessageTypes.Video)
                Positioned(
                  bottom: ChatDetailsMediaStyle.durationPosition,
                  right: ChatDetailsMediaStyle.durationPosition,
                  child: Container(
                    padding: ChatDetailsMediaStyle.durationPadding,
                    decoration: ChatDetailsMediaStyle.durationBoxDecoration(
                      context,
                    ),
                    child: Text(
                      "00:00",
                      style: ChatDetailsMediaStyle.durationTextStyle(context),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
