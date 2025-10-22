import 'dart:ui';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/pages/chat/group_chat_empty_view.dart';
import 'package:fluffychat/pages/chat/optional_selection_area.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_empty_widget.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:inview_notifier_list/inview_notifier_list.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ChatEventList extends StatelessWidget {
  final ChatController controller;

  const ChatEventList({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = TwakeThemes.isColumnMode(context) ? 16.0 : 0.0;

    // Group consecutive image events
    final groupedEvents = controller.groupedEvents;

    // create a map of eventId --> grouped index to greatly improve performance of
    // ListView's findChildIndexCallback
    // This maps all event IDs (including those in groups) to their group's index
    final thisEventsKeyMap = <String, int>{};
    for (var i = 0; i < groupedEvents.length; i++) {
      final group = groupedEvents[i];
      // Map the main event and all additional events to the same group index
      for (final event in group.allEvents) {
        // Add 1 to account for the first item (footer)
        thisEventsKeyMap[event.eventId] = i + 1;
      }
    }

    if (controller.hasNoMessageEvents) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            switch (notification.runtimeType) {
              case const (ScrollStartNotification):
                controller.handleScrollStartNotification();
                break;
              case const (ScrollEndNotification):
                controller.handleScrollEndNotification();
                break;
              case const (ScrollUpdateNotification):
                controller.handleScrollUpdateNotification();
                break;
              default:
                break;
            }
            return false;
          },
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: dragDevicesSupported(),
            ),
            child: OptionalSelectionArea(
              isEnabled: PlatformInfos.isWeb && !controller.selectMode,
              child: InViewNotifierListCustom(
                isInViewPortCondition: controller.isInViewPortCondition,
                listViewCustom: ListView.custom(
                  padding: EdgeInsets.only(
                    top: 16,
                    bottom: 8.0,
                    left: horizontalPadding,
                    right: horizontalPadding,
                  ),
                  reverse: true,
                  controller: controller.scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  childrenDelegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      // Footer to display typing indicator and read receipts:
                      if (index == 0) {
                        if (controller.timeline!.isRequestingFuture) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }
                        if (controller.timeline!.canRequestFuture) {
                          Center(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                              onPressed: controller.requestFuture,
                              child: Text(L10n.of(context)!.loadMore),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      // Request history button or progress indicator:
                      if (index == groupedEvents.length + 1) {
                        if (controller.timeline!.isRequestingHistory) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }
                        if (controller.timeline!.canRequestHistory) {
                          return Center(
                            child: IconButton(
                              onPressed: controller.requestHistory,
                              icon: const Icon(Icons.refresh_outlined),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final currentGroupIndex = index - 1;
                      final group = groupedEvents[currentGroupIndex];
                      final event = group.mainEvent;

                      final previousEvent = currentGroupIndex > 0
                          ? groupedEvents[currentGroupIndex - 1].mainEvent
                          : null;
                      final nextEvent =
                          currentGroupIndex < groupedEvents.length - 1
                              ? groupedEvents[currentGroupIndex + 1].mainEvent
                              : null;
                      return event.isVisibleInGui
                          ? AutoScrollTag(
                              key: ValueKey(event.eventId),
                              index: index,
                              controller: controller.scrollController,
                              highlightColor: Theme.of(context).highlightColor,
                              child: Message(
                                key: ValueKey(event.eventId),
                                event,
                                matrixState: controller.matrix!,
                                onSwipe: (direction) =>
                                    controller.replyAction(replyTo: event),
                                onAvatarTap: (Event event) =>
                                    controller.onContactTap(
                                  contactPresentationSearch: event
                                      .senderFromMemoryOrFallback
                                      .toContactPresentationSearch(),
                                  context: context,
                                  path: 'rooms',
                                ),
                                onSelect: controller.onSelectMessage,
                                selectMode: controller.selectMode,
                                maxWidth: constraints.maxWidth,
                                scrollToEventId: (String eventId) =>
                                    controller.scrollToEventId(
                                  eventId,
                                  highlight: true,
                                ),
                                selected: controller.selectedEvents
                                    .any((e) => e.eventId == event.eventId),
                                timeline: controller.timeline!,
                                previousEvent: previousEvent,
                                nextEvent: nextEvent,
                                onHover: (isHover, event) =>
                                    controller.onHover(isHover, index, event),
                                isHoverNotifier: controller.focusHover,
                                listHorizontalActionMenu: controller
                                    .listHorizontalActionMenuBuilder(event),
                                onMenuAction:
                                    controller.handleHorizontalActionMenu,
                                hideKeyboardChatScreen:
                                    controller.onHideKeyboardAndEmoji,
                                markedUnreadLocation:
                                    controller.unreadReceivedMessageLocation,
                                timestampCallback: (event) {
                                  controller.handleDisplayStickyTimestamp(
                                    event.originServerTs,
                                  );
                                },
                                onDisplayEmojiReaction:
                                    controller.onDisplayEmojiReaction,
                                onHideEmojiReaction:
                                    controller.onHideEmojiReaction,
                                listAction: controller
                                    .listHorizontalActionMenuBuilder(event)
                                    .map((action) {
                                  return ContextMenuAction(
                                    name: action.action.name,
                                  );
                                }).toList(),
                                onPickEmojiReaction: () {},
                                onSelectEmojiReaction: (emoji, event) {
                                  controller.sendEmojiAction(
                                    emoji: emoji,
                                    event: event,
                                  );
                                },
                                onForward: (event) {
                                  controller.forwardEventsAction(event: event);
                                },
                                onReply: (event) {
                                  controller.replyAction(replyTo: event);
                                },
                                onCopy: controller.copyEventsAction,
                                onPin: (event) {
                                  controller.pinEventAction(event);
                                },
                                onSaveToDownload: (event) => controller
                                    .saveSelectedEventToDownloadAndroid(
                                  context,
                                  event,
                                ),
                                onSaveToGallery: (event) => controller
                                    .saveSelectedEventToGallery(context, event),
                                onTapMoreButton:
                                    controller.handleOnTapMoreButtonOnWeb,
                                onEdit: (event) {
                                  controller.editAction(editEvent: event);
                                },
                                onDelete: (context, event) {
                                  controller.deleteEventAction(context, event);
                                },
                                recentEmojiFuture: controller
                                    .getRecentReactionsInteractor
                                    .execute(),
                                onReport: controller.reportEventAction,
                                groupedEvents: group.isGrouped ? group : null,
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                    childCount: groupedEvents.length + 2,
                    findChildIndexCallback: (key) => controller
                        .findChildIndexCallback(key, thisEventsKeyMap),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Set<PointerDeviceKind>? dragDevicesSupported() {
    if (PlatformInfos.isWeb) {
      return {
        PointerDeviceKind.touch,
      };
    }
    return {
      PointerDeviceKind.touch,
      PointerDeviceKind.mouse,
      PointerDeviceKind.trackpad,
    };
  }

  Widget _chatEmptyBuilder(Timeline timeline) {
    if (controller.room?.isDirectChat ?? true) {
      return DraftChatEmpty(
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
