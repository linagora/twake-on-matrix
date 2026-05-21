import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/pages/chat/events/message/message_selected_widget.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:fluffychat/pages/chat/events/message/swipeable_message.dart';
import 'package:fluffychat/pages/chat/optional_gesture_detector.dart';
import 'package:fluffychat/pages/chat/optional_padding.dart';
import 'package:fluffychat/utils/extension/event_status_custom_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class MessageContainer extends StatelessWidget {
  final Event event;
  final Widget row;
  final bool selected;
  final bool selectMode;
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
    this.onHover,
    this.onSwipe,
    this.onSelect,
    this.hideKeyboardChatScreen,
    this.autoScrollController,
    this.scrollIndex,
  });

  EdgeInsetsDirectional _rowPadding(BuildContext context) {
    const double sidePadding = 16.0;
    final isMobile = Message.responsiveUtils.isMobile(context);
    final selectedWidgetLeftPadding = isMobile ? 8.0 : 0.0;

    if (event.shouldAlignOwnMessageInDifferentSide) {
      return const EdgeInsetsDirectional.only(end: sidePadding);
    }
    return EdgeInsetsDirectional.only(
      start: sidePadding - selectedWidgetLeftPadding,
      end: sidePadding,
    );
  }

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
        padding: MessageStyle.paddingMessage,
        child: SwipeableMessage(
          event: event,
          onSwipe: onSwipe,
          child: OptionalGestureDetector(
            onLongPress: () => onSelect!(event),
            onTap: () => onSelect!(event),
            isEnabled: selectMode && event.status.isAvailable,
            child: OptionalPadding(
              padding: _rowPadding(context),
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

    // SizedBox forces the Stack to fill the full row width so the highlight
    // color spans the screen. Positioned.fill paints behind the content
    // without affecting the message layout.
    final highlighted = SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          if (selected)
            Positioned.fill(
              child: ColoredBox(
                color: LinagoraSysColors.material().secondaryContainer,
              ),
            ),
          container,
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
        highlightColor: Theme.of(context).highlightColor,
        child: highlighted,
      );
    }
    return highlighted;
  }
}
