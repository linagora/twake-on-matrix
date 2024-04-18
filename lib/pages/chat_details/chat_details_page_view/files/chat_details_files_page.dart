import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item_web/chat_details_files_item_web.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_page_style.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_builder.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_controller.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';

class ChatDetailsFilesPage extends StatelessWidget {
  final SameTypeEventsBuilderController controller;

  const ChatDetailsFilesPage({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ChatDetailsFilesPageStyle.horizontalPadding,
      child: SameTypeEventsBuilder(
        controller: controller,
        builder: (context, eventsState, _) {
          final events = eventsState
                  .getSuccessOrNull<TimelineSearchEventSuccess>()
                  ?.events ??
              [];
          return SliverList.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              if (!PlatformInfos.isWeb) {
                return ChatDetailsFileItem(event: events[index]);
              }
              return ChatDetailsFileItemWeb(event: events[index]);
            },
          );
        },
      ),
    );
  }
}
