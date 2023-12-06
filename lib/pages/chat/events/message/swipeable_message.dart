import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/widgets/swipeable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';

class SwipeableMessage extends StatelessWidget {
  final Event event;

  final void Function(SwipeDirection)? onSwipe;

  final Widget child;

  const SwipeableMessage({
    super.key,
    required this.event,
    required this.child,
    this.onSwipe,
  });

  static const maxOffset = 0.4;

  static const swipeIntensity = 2.5;

  static const movementDuration = Duration(milliseconds: 100);

  @override
  Widget build(BuildContext context) {
    if (onSwipe == null) {
      return child;
    }
    return Swipeable(
      key: ValueKey(event.eventId),
      background: Padding(
        padding: MessageStyle.paddingSwipeMessage,
        child: const Center(
          child: Icon(Icons.reply_outlined),
        ),
      ),
      onOverScrollTheMaxOffset: () => HapticFeedback.heavyImpact(),
      maxOffset: maxOffset,
      movementDuration: movementDuration,
      swipeIntensity: swipeIntensity,
      direction: SwipeDirection.endToStart,
      onSwipe: onSwipe!,
      child: child,
    );
  }
}
