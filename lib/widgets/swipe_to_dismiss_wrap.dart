import 'package:flutter/material.dart';

class SwipeToDismissWrap extends StatefulWidget {
  final Widget child;

  const SwipeToDismissWrap({super.key, required this.child});

  @override
  State<SwipeToDismissWrap> createState() => _SwipeToDismissWrapState();
}

class _SwipeToDismissWrapState extends State<SwipeToDismissWrap> {
  bool _swipeInProgress = false;
  double _startPosX = 0;

  static const double _swipeStartAreaWidth = 60;
  static const double _swipeMinLength = 50;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        if (details.localPosition.dx < _swipeStartAreaWidth) {
          _swipeInProgress = true;
          _startPosX = details.localPosition.dx;
        }
      },
      onHorizontalDragUpdate: (details) {
        if (_swipeInProgress &&
            details.localPosition.dx > _startPosX + _swipeMinLength) {
          Navigator.of(context).pop();
        }
      },
      onHorizontalDragEnd: (_) => _swipeInProgress = false,
      child: widget.child,
    );
  }
}
