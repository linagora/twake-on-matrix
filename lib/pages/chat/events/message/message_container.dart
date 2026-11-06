import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:twake_chat/pages/chat/chat_view_body_style.dart';
import 'package:twake_chat/pages/chat/events/message/message.dart';
import 'package:twake_chat/pages/chat/events/message/message_selected_widget.dart';
import 'package:twake_chat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:twake_chat/pages/chat/events/message/swipeable_message.dart';
import 'package:twake_chat/pages/chat/optional_gesture_detector.dart';
import 'package:twake_chat/pages/chat/optional_padding.dart';
import 'package:twake_chat/utils/extension/event_status_custom_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class MessageContainer extends StatelessWidget {
  final Event event;
  final Widget row;
  final bool selected;
  final bool selectMode;
  final ValueNotifier<String?>? highlightedEventIdNotifier;
  final OnHover? onHover;
  final OnSwipe? onSwipe;
  final OnSelect? onSelect;
  final VoidCallback? hideKeyboardChatScreen;
  final AutoScrollController? autoScrollController;
  final int? scrollIndex;

  const MessageContainer({
    super.key,
    required this.event,
    required this.row,
    required this.selected,
    required this.selectMode,
    this.highlightedEventIdNotifier,
    this.onHover,
    this.onSwipe,
    this.onSelect,
    this.hideKeyboardChatScreen,
    this.autoScrollController,
    this.scrollIndex,
  });

  @override
  Widget build(BuildContext context) {
    final container = MultiPlatformsMessageContainer(
      onTap: hideKeyboardChatScreen,
      onHover: (hover) {
        if (event.status.isAvailable || event.status.isError) {
          onHover?.call(hover, event);
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ChatViewBodyStyle.chatScreenMaxWidth,
        ),
        alignment: Alignment.bottomCenter,
        child: SwipeableMessage(
          event: event,
          onSwipe: onSwipe,
          child: OptionalGestureDetector(
            onLongPress: () => onSelect!(event),
            onTap: () => onSelect!(event),
            isEnabled: selectMode && event.status.isAvailable,
            child: OptionalPadding(
              padding: EdgeInsetsDirectional.only(
                end:
                    event.isOwnMessage ||
                        Message.responsiveUtils.isDesktop(context)
                    ? 8.0
                    : 16.0,
              ),
              isEnabled: !selected,
              child: MessageSelectedWidget(
                event: event,
                selected: selected,
                selectMode: selectMode,
                child: row,
              ),
            ),
          ),
        ),
      ),
    );

    final highlightTint = LinagoraSysColors.material().warning.withValues(
      alpha: 0.12,
    );

    // Outer SizedBox(∞) gives the Stack a bounded width.
    // Inner SizedBox(∞) wrapping container forces it to fill that width,
    // overriding Container's tendency to shrink-wrap to its child.
    // Being non-positioned, it also determines the Stack's height.
    final highlighted = SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: _MessageBackground(
              eventId: event.eventId,
              selected: selected,
              highlightTint: highlightTint,
              highlightedEventIdNotifier: highlightedEventIdNotifier,
            ),
          ),
          SizedBox(width: double.infinity, child: container),
        ],
      ),
    );

    final controller = autoScrollController;
    final scrollIdx = scrollIndex;
    if (controller != null && scrollIdx != null) {
      return AutoScrollTag(
        key: ValueKey(event.eventId),
        index: scrollIdx,
        controller: controller,
        highlightColor: highlightTint,
        child: highlighted,
      );
    }
    return highlighted;
  }
}

class _MessageBackground extends StatelessWidget {
  final String eventId;
  final bool selected;
  final Color highlightTint;
  final ValueNotifier<String?>? highlightedEventIdNotifier;

  const _MessageBackground({
    required this.eventId,
    required this.selected,
    required this.highlightTint,
    this.highlightedEventIdNotifier,
  });

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return ColoredBox(color: LinagoraSysColors.material().secondaryContainer);
    }
    final highlightedEventIdNotifier = this.highlightedEventIdNotifier;
    if (highlightedEventIdNotifier == null) return const SizedBox.shrink();
    return ValueListenableBuilder<String?>(
      valueListenable: highlightedEventIdNotifier,
      builder: (context, highlightedEventId, _) => highlightedEventId == eventId
          ? ColoredBox(color: highlightTint)
          : const SizedBox.shrink(),
    );
  }
}
