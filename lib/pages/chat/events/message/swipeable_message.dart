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

  @override
  Widget build(BuildContext context) {
    if (onSwipe == null) {
      return child;
    }
    return Swipeable(
      key: ValueKey(event.eventId),
      background: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: Center(
          child: Icon(Icons.reply_outlined),
        ),
      ),
      onOverScrollTheMaxOffset: () => HapticFeedback.heavyImpact(),
      maxOffset: 0.4,
      movementDuration: const Duration(milliseconds: 100),
      swipeIntensity: 2.5,
      direction: SwipeDirection.endToStart,
      onSwipe: onSwipe!,
      child: child,
    );
  }
}
