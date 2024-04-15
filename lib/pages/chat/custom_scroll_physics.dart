import 'package:flutter/material.dart';

class PositionRetainedScrollPhysics extends ScrollPhysics {
  final bool shouldRetain;
  const PositionRetainedScrollPhysics(
      {ScrollPhysics? parent, this.shouldRetain = true})
      : super(parent: parent);

  @override
  PositionRetainedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PositionRetainedScrollPhysics(
      parent: buildParent(ancestor),
      shouldRetain: shouldRetain,
    );
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final position = super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );

    final diff = newPosition.maxScrollExtent - oldPosition.maxScrollExtent;
    if (oldPosition.pixels == 0 && newPosition.pixels == 0) {
      if (newPosition.maxScrollExtent > oldPosition.maxScrollExtent &&
          diff > 0 &&
          shouldRetain) {
        return diff;
      } else {
        return position;
      }
    } else {
      return position;
    }
  }
}
