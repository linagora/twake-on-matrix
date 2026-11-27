import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/chat_scroll_view.dart';
import 'package:twake_chat/pages/chat/chat_web_scrollbar.dart';
import 'package:twake_chat/pages/chat/empty_support_chat_view.dart';
import 'package:twake_chat/pages/chat/group_chat_empty_view.dart';
import 'package:twake_chat/pages/chat/optional_selection_area.dart';
import 'package:twake_chat/pages/chat_draft/draft_chat_empty_widget.dart';
import 'package:twake_chat/providers/personalization/display_preferences_controller.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/room_status_extension.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatEventList extends ConsumerWidget {
  final ChatController controller;

  const ChatEventList({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = List<Event>.from(controller.eventsToDisplay);
    final seenStyle = ref.watch(
      displayPreferencesProvider.select((preferences) => preferences.seenStyle),
    );

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
            switch (notification) {
              case ScrollStartNotification():
                controller.handleScrollStartNotification();
                break;
              case ScrollEndNotification():
                controller.handleScrollEndNotification();
                break;
              case ScrollUpdateNotification():
                controller.handleScrollUpdateNotification();
                break;
              default:
                break;
            }
            return false;
          },
          child: _buildScrollArea(controller, events, constraints, seenStyle),
        );
      },
    );
  }

  /// Who stopped reading at each own message, for the whole timeline at once.
  /// The ticks show nobody, so nothing is worked out for them.
  Map<String, List<User>> _readersByEvent(SeenStyle seenStyle) {
    if (seenStyle == SeenStyle.ticks) return const {};
    final timeline = controller.timeline;
    if (timeline == null) return const {};
    return controller.room?.readersStoppedAtByEvent(timeline) ?? const {};
  }

  Widget _buildScrollArea(
    ChatController chatController,
    List<Event> events,
    BoxConstraints constraints,
    SeenStyle seenStyle,
  ) {
    final chatScrollView = Listener(
      onPointerDown: (_) => chatController.clearHighlightedEvent(),
      onPointerSignal: (_) => chatController.clearHighlightedEvent(),
      onPointerPanZoomStart: (_) => chatController.clearHighlightedEvent(),
      child: ChatScrollView(
        key: PageStorageKey('ChatScrollView-${chatController.room?.id}'),
        events: events,
        controller: chatController,
        constraints: constraints,
        readersByEvent: _readersByEvent(seenStyle),
      ),
    );

    if (PlatformInfos.isDesktop) {
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
  Set<PointerDeviceKind> get dragDevices =>
      super.dragDevices.difference({PointerDeviceKind.mouse});

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
