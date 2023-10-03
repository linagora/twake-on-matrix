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
  });

  final Widget child;
  final double dismissThreshold;
  final VoidCallback? onDismissed;
  final bool enabled;
  final Function(DragStartDetails dragStartDetails)? handleDragStart;
  final Function(DragEndDetails dragEndDetails)? handleDragEnd;

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
      Tween<Offset>(
        begin: Offset.zero,
        end: Offset(0, end),
      ),
    );

    _scaleAnimation = _animateController.drive(
      Tween<double>(
        begin: 1,
        end: 0.5,
      ),
    );

    _opacityAnimation = DecorationTween(
      begin: BoxDecoration(
        color: Colors.black.withOpacity(1.0),
      ),
      end: BoxDecoration(
        color: Colors.black.withOpacity(0.0),
      ),
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

  @override
  Widget build(BuildContext context) {
    final Widget content = DecoratedBoxTransition(
      decoration: _opacityAnimation,
      child: SlideTransition(
        position: _moveAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: widget.enabled ? _handleDragStart : null,
      onVerticalDragUpdate: widget.enabled ? _handleDragUpdate : null,
      onVerticalDragEnd: widget.enabled ? _handleDragEnd : null,
      child: content,
    );
  }
}
