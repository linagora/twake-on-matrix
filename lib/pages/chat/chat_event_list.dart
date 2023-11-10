import 'package:fluffychat/pages/chat/group_chat_empty_view.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_empty_view.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/pages/user_bottom_sheet/user_bottom_sheet.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';

class ChatEventList extends StatelessWidget {
  final ChatController controller;

  const ChatEventList({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = TwakeThemes.isColumnMode(context) ? 8.0 : 0.0;

    // create a map of eventId --> index to greatly improve performance of
    // ListView's findChildIndexCallback
    final thisEventsKeyMap = <String, int>{};
    for (var i = 0; i < controller.timeline!.events.length; i++) {
      thisEventsKeyMap[controller.timeline!.events[i].eventId] = i;
    }

    if (controller.isEmptyChat) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                controller: controller.scrollController,
                physics: const ClampingScrollPhysics(),
                child: _chatEmptyBuilder(controller.timeline!),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.custom(
      padding: EdgeInsets.only(
        top: 16,
        bottom: 8.0,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      reverse: true,
      controller: controller.scrollController,
      keyboardDismissBehavior: PlatformInfos.isMobile
          ? ScrollViewKeyboardDismissBehavior.manual
          : ScrollViewKeyboardDismissBehavior.onDrag,
      childrenDelegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          // Footer to display typing indicator and read receipts:
          if (index == 0) {
            return const SizedBox.shrink();
          }
          // Request history button or progress indicator:
          if (index == controller.timeline!.events.length + 1) {
            if (controller.timeline!.isRequestingHistory) {
              return const Center(
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              );
            }
            if (controller.canLoadMore) {
              Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  onPressed: controller.requestHistory,
                  child: Text(L10n.of(context)!.loadMore),
                ),
              );
            }
            return Container();
          }

          // The message at this index:
          final currentEventIndex = index - 1;
          final event = controller.timeline!.events[currentEventIndex];
          final previousEvent = currentEventIndex > 0
              ? controller.timeline!.events[currentEventIndex - 1]
              : null;
          final nextEvent = index < controller.timeline!.events.length
              ? controller.timeline!.events[currentEventIndex + 1]
              : null;
          return AutoScrollTag(
            key: ValueKey(event.eventId),
            index: currentEventIndex,
            controller: controller.scrollController,
            highlightColor: LinagoraRefColors.material().primary[99],
            child: event.isVisibleInGui
                ? Message(
                    event,
                    onSwipe: (direction) =>
                        controller.replyAction(replyTo: event),
                    onAvatarTab: (Event event) => showAdaptiveBottomSheet(
                      context: context,
                      builder: (c) => UserBottomSheet(
                        user: event.senderFromMemoryOrFallback,
                        outerContext: context,
                        onMention: () => controller.sendController.text +=
                            '${event.senderFromMemoryOrFallback.mention} ',
                      ),
                    ),
                    onSelect: controller.onSelectMessage,
                    scrollToEventId: (String eventId) =>
                        controller.scrollToEventId(eventId),
                    longPressSelect: controller.selectedEvents.isEmpty,
                    selected: controller.selectedEvents
                        .any((e) => e.eventId == event.eventId),
                    timeline: controller.timeline!,
                    previousEvent: previousEvent,
                    nextEvent: nextEvent,
                    controller: controller,
                    onHover: (isHover, event) =>
                        controller.onHover(isHover, index, event),
                    isHover: controller.focusHover,
                    listHorizontalActionMenu:
                        controller.listHorizontalActionMenuBuilder(),
                    onMenuAction: controller.handleHorizontalActionMenu,
                  )
                : Container(),
          );
        },
        childCount: controller.timeline!.events.length + 2,
        findChildIndexCallback: (key) =>
            controller.findChildIndexCallback(key, thisEventsKeyMap),
      ),
    );
  }

  Widget _chatEmptyBuilder(Timeline timeline) {
    if (controller.room?.isDirectChat ?? true) {
      return DirectDraftChatView(
        onTap: () => controller.inputFocus.requestFocus(),
      );
    } else {
      return _groupChatEmptyBuilder(timeline);
    }
  }

  Widget _groupChatEmptyBuilder(Timeline timeline) {
    if (timeline.events.isNotEmpty) {
      return GroupChatEmptyView(
        firstEvent: timeline.events.last,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
