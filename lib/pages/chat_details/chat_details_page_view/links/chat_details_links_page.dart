import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/links/chat_details_links_item.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_builder.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_controller.dart';

class ChatDetailsLinksPage extends StatelessWidget {
  final SameTypeEventsBuilderController controller;

  const ChatDetailsLinksPage({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SameTypeEventsBuilder(
      controller: controller,
      builder: (context, eventsState, _) {
        final events = eventsState
                .getSuccessOrNull<TimelineSearchEventSuccess>()
                ?.events ??
            [];
        return SliverList.separated(
          itemCount: events.length,
          itemBuilder: (context, index) {
            return ChatDetailsLinkItem(event: events[index]);
          },
          separatorBuilder: (context, index) => const Divider(),
        );
      },
    );
  }
}
