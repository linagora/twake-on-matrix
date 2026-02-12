import 'dart:ui';

import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_scroll_view.dart';
import 'package:fluffychat/pages/chat/empty_support_chat_view.dart';
import 'package:fluffychat/pages/chat/group_chat_empty_view.dart';
import 'package:fluffychat/pages/chat/optional_selection_area.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_empty_widget.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatEventList extends StatelessWidget {
  final ChatController controller;

  const ChatEventList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final events = List<Event>.from(controller.timeline!.events);

    if (controller.isEmptySupportChat) {
      return const EmptySupportChatView();
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
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(dragDevices: dragDevicesSupported()),
            child: OptionalSelectionArea(
              isEnabled: PlatformInfos.isWeb && !controller.selectMode,
              child: ChatScrollView(
                key: PageStorageKey('ChatScrollView-${controller.room?.id}'),
                events: events,
                controller: controller,
                constraints: constraints,
              ),
            ),
          ),
        );
      },
    );
  }

  Set<PointerDeviceKind>? dragDevicesSupported() {
    if (PlatformInfos.isWeb) {
      return {PointerDeviceKind.touch};
    }
    return {
      PointerDeviceKind.touch,
      PointerDeviceKind.mouse,
      PointerDeviceKind.trackpad,
    };
  }

  Widget _chatEmptyBuilder(Timeline timeline) {
    if (controller.room?.isDirectChat ?? true) {
      return DraftChatEmpty(onTap: () => controller.inputFocus.requestFocus());
    } else {
      return _groupChatEmptyBuilder(timeline);
    }
  }

  Widget _groupChatEmptyBuilder(Timeline timeline) {
    if (timeline.events.isNotEmpty) {
      return GroupChatEmptyView(firstEvent: timeline.events.last);
    } else {
      return const SizedBox.shrink();
    }
  }
}
