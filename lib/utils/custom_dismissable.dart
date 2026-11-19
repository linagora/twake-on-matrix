import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CustomDismissible extends StatefulWidget {
  const CustomDismissible({
    super.key,
    required this.child,
    this.onDismissed,
    this.dismissThreshold = 0.2,
    this.enabled = true,
    this.handleDragStart,
    this.handleDragEnd,
    this.dismissOverChildDrags = false,
  });

  final Widget child;
  final double dismissThreshold;
  final VoidCallback? onDismissed;
  final bool enabled;
  final Function(DragStartDetails dragStartDetails)? handleDragStart;
  final Function(DragEndDetails dragEndDetails)? handleDragEnd;

  /// Raw pointers, so a child that claims vertical drags cannot block it.
  final bool dismissOverChildDrags;

  @override
  State<CustomDismissible> createState() => _CustomDismissibleState();
}

class _CustomDismissibleState extends State<CustomDismissible>
    with SingleTickerProviderStateMixin {
  late AnimationController _animateController;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Decoration> _opacityAnimation;

  static const animationDuration = Duration(milliseconds: 300);

  double _dragExtent = 0;
  bool _dragUnderway = false;
  int? _pointer;
  Offset _pointerDownPosition = Offset.zero;

  bool get _isActive => _dragUnderway || _animateController.isAnimating;

  @override
  void initState() {
    super.initState();

    _animateController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );

    _updateMoveAnimation();
  }

  @override
  void dispose() {
    _animateController.dispose();

    super.dispose();
  }

  void _updateMoveAnimation() {
    final double end = _dragExtent.sign;

    _moveAnimation = _animateController.drive(
      Tween<Offset>(begin: Offset.zero, end: Offset(0, end)),
    );

    _scaleAnimation = _animateController.drive(
      Tween<double>(begin: 1, end: 0.5),
    );

    _opacityAnimation = DecorationTween(
      begin: BoxDecoration(color: Colors.black.withOpacity(1.0)),
      end: BoxDecoration(color: Colors.black.withOpacity(0.0)),
    ).animate(_animateController);
  }

  void _handleDragStart(DragStartDetails details) {
    widget.handleDragStart?.call(details);
    _dragUnderway = true;

    if (_animateController.isAnimating) {
      _dragExtent =
          _animateController.value * context.size!.height * _dragExtent.sign;
      _animateController.stop();
    } else {
      _dragExtent = 0.0;
      _animateController.value = 0.0;
    }
    setState(_updateMoveAnimation);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isActive || _animateController.isAnimating) {
      return;
    }

    final double delta = details.primaryDelta!;
    final double oldDragExtent = _dragExtent;

    if (_dragExtent + delta < 0) {
      _dragExtent += delta;
    } else if (_dragExtent + delta > 0) {
      _dragExtent += delta;
    }

    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(_updateMoveAnimation);
    }

    if (!_animateController.isAnimating) {
      _animateController.value = _dragExtent.abs() / context.size!.height;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    widget.handleDragEnd?.call(details);
    if (!_isActive || _animateController.isAnimating) {
      return;
    }

    _dragUnderway = false;

    if (_animateController.isCompleted) {
      return;
    }

    if (!_animateController.isDismissed) {
      // if the dragged value exceeded the dismissThreshold, call onDismissed
      // else animate back to initial position.
      if (_animateController.value > widget.dismissThreshold) {
        widget.onDismissed?.call();
      } else {
        _animateController.reverse();
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _pointerDownPosition = event.position;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    if (!_dragUnderway) {
      final offset = event.position - _pointerDownPosition;
      if (offset.distance <= kTouchSlop) return;
      if (offset.dy.abs() <= offset.dx.abs()) {
        _pointer = null;
        return;
      }
      _handleDragStart(DragStartDetails(globalPosition: event.position));
    }
    _handleDragUpdate(
      DragUpdateDetails(
        globalPosition: event.position,
        delta: Offset(0, event.delta.dy),
        primaryDelta: event.delta.dy,
      ),
    );
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    if (_dragUnderway) _handleDragEnd(DragEndDetails());
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = DecoratedBoxTransition(
      decoration: _opacityAnimation,
      child: SlideTransition(
        position: _moveAnimation,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );

    if (widget.dismissOverChildDrags) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: widget.enabled ? _handlePointerDown : null,
        onPointerMove: widget.enabled ? _handlePointerMove : null,
        onPointerUp: _handlePointerEnd,
        onPointerCancel: _handlePointerEnd,
        child: content,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: widget.enabled ? _handleDragStart : null,
      onVerticalDragUpdate: widget.enabled ? _handleDragUpdate : null,
      onVerticalDragEnd: widget.enabled ? _handleDragEnd : null,
      child: content,
    );
  }
}
