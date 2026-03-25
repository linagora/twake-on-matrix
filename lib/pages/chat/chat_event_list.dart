import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_scroll_view.dart';
import 'package:fluffychat/pages/chat/chat_web_scrollbar.dart';
import 'package:fluffychat/pages/chat/empty_support_chat_view.dart';
import 'package:fluffychat/pages/chat/group_chat_empty_view.dart';
import 'package:fluffychat/pages/chat/optional_selection_area.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_empty_widget.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/gestures.dart';
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
          child: _buildScrollArea(context, controller, events, constraints),
        );
      },
    );
  }

  Widget _buildScrollArea(
    BuildContext context,
    ChatController chatController,
    List<Event> events,
    BoxConstraints constraints,
  ) {
    final chatScrollView = ChatScrollView(
      key: PageStorageKey('ChatScrollView-${chatController.room?.id}'),
      events: events,
      controller: chatController,
      constraints: constraints,
    );

    if (PlatformInfos.isWeb) {
      return ChatWebScrollbar(
        controller: chatController.scrollController,
        child: ScrollConfiguration(
          behavior: const _WebContentScrollBehavior(),
          child: OptionalSelectionArea(
            isEnabled: !chatController.selectMode,
            child: chatScrollView,
          ),
        ),
      );
    }

    return OptionalSelectionArea(isEnabled: false, child: chatScrollView);
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

class _WebContentScrollBehavior extends MaterialScrollBehavior {
  const _WebContentScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch};

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
