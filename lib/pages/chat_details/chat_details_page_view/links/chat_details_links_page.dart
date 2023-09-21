import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/links/chat_details_links_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat_details/chat_details_page_view/same_type_events_list_controller.dart';

class ChatDetailsLinksPage extends StatelessWidget {
  static const _linksFetchLimit = 20;
  final Future<Timeline> Function() getTimeline;

  const ChatDetailsLinksPage({
    Key? key,
    required this.getTimeline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SameTypeEventsListBuilder(
      getTimeline: getTimeline,
      searchFunc: (event) => event.isContainsLink,
      limit: _linksFetchLimit,
      builder: (context, eventsState) {
        final events = eventsState
                .getSuccessOrNull<TimelineSearchEventSuccess>()
                ?.events ??
            [];
        return SliverList.separated(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final body = events[index].body;
            final link = body.getFirstValidUrl() ?? '';
            return ListTile(
              leading: Container(
                width: ChatDetailsLinksStyle.avatarSize,
                height: ChatDetailsLinksStyle.avatarSize,
                alignment: Alignment.center,
                decoration: ChatDetailsLinksStyle.avatarDecoration(context),
                child: Text(
                  link.getShortcutNameForAvatar(),
                  style: ChatDetailsLinksStyle.avatarTextStyle(context),
                ),
              ),
              title: Text(link),
              subtitle: Text(
                link,
                style: ChatDetailsLinksStyle.subtitleTextStyle(context),
              ),
            );
          },
          separatorBuilder: (context, index) => const Divider(),
        );
      },
    );
  }
}
