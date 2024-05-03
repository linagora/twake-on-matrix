import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kFlingVelocityScale = 1.0 / 300.0;
const double _kDismissThreshold = 0.4;

/// Signature used by [Swipeable] to indicate that it has been swiped in
/// the given `direction`.
///
/// Used by [Swipeable.onSwipe].
typedef SwipeDirectionCallback = void Function(SwipeDirection direction);

/// Signature used by [Swipeable] to give the application an opportunity to
/// confirm or veto a swipe gesture.
///
/// Used by [Swipeable.confirmSwipe].
typedef ConfirmSwipeCallback = Future<bool> Function(SwipeDirection direction);

typedef OnOverScrollTheMaxOffset = void Function();

/// The direction in which a [Swipeable] can be swiped.
enum SwipeDirection {
  /// The [Swipeable] can be swiped by dragging either left or right.
  horizontal,

  /// The [Swipeable] can be swiped by dragging in the reverse of the
  /// reading direction (e.g., from right to left in left-to-right languages).
  endToStart,

  /// The [Swipeable] can be swiped by dragging in the reading direction
  /// (e.g., from left to right in left-to-right languages).
  startToEnd,

  /// Called instead of null.
  none,
}

class Swipeable extends StatefulWidget {
  /// Creates a widget that calls a function when swiped.
  ///
  /// The [key] argument must not be null because [Swipeable]s are commonly
  /// used in lists and removed from the list when dismissed. Without keys, the
  /// default behavior is to sync widgets based on their index in the list,
  /// which means the item after the dismissed item would be synced with the
  /// state of the dismissed item. Using keys causes the widgets to sync
  /// according to their keys and avoids this pitfall.
  const Swipeable({
    required Key key,
    required this.child,
    required this.onSwipe,
    this.background,
    this.secondaryBackground,
    this.confirmSwipe,
    this.direction = SwipeDirection.horizontal,
    this.dismissThresholds = const <SwipeDirection, double>{},
    this.maxOffset = 0.4,
    this.movementDuration = const Duration(milliseconds: 200),
    this.crossAxisEndOffset = 0.0,
    this.dragStartBehavior = DragStartBehavior.start,
    this.swipeIntensity = 1.0,
    this.allowedPointerKinds = const {
      PointerDeviceKind.invertedStylus,
      PointerDeviceKind.stylus,
      PointerDeviceKind.touch,
    },
    this.onOverScrollTheMaxOffset,
  })  : assert(secondaryBackground == null || background != null),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// A widget that is stacked behind the child. If secondaryBackground is also
  /// specified then this widget only appears when the child has been dragged
  /// to the right.
  final Widget? background;

  /// A widget that is stacked behind the child and is exposed when the child
  /// has been dragged to the left. It may only be specified when background
  /// has also been specified.
  final Widget? secondaryBackground;

  /// Gives the app an opportunity to confirm or veto a pending dismissal.
  ///
  /// If the returned Future<bool> completes true, then this widget will be
  /// dismissed, otherwise it will be moved back to its original location.
  ///
  /// If the returned Future<bool> completes to false or null the [onSwipe]
  /// callback will not run.
  final ConfirmSwipeCallback? confirmSwipe;

  /// Called when the widget has been dismissed, after finishing resizing.
  final SwipeDirectionCallback onSwipe;

  /// The direction in which the widget can be dismissed.
  final SwipeDirection direction;

  /// The offset threshold the item has to be dragged in order to be considered
  /// dismissed.
  ///
  /// Represented as a fraction, e.g. if it is 0.4 (the default), then the item
  /// has to be dragged at least 40% towards one direction to be considered
  /// dismissed. Clients can define different thresholds for each dismiss
  /// direction.
  ///
  /// Flinging is treated as being equivalent to dragging almost to 1.0, so
  /// flinging can dismiss an item past any threshold less than 1.0.
  ///
  /// Setting a threshold of 1.0 (or greater) prevents a drag in the given
  /// [SwipeDirection] even if it would be allowed by the [direction]
  /// property.
  ///
  /// See also:
  ///
  ///  * [direction], which controls the directions in which the items can
  ///    be dismissed.
  final Map<SwipeDirection, double> dismissThresholds;

  /// The maximum horizontal offset the item can move to/
  ///
  /// Represented as a fraction, e.g. if it is 0.4 (the default), then the
  /// item can be moved at maximum 40% of item's width.
  final double maxOffset;

  /// Defines the duration for card to dismiss or to come back to original position if not dismissed.
  final Duration movementDuration;

  /// Defines the end offset across the main axis after the card is dismissed.
  ///
  /// If non-zero value is given then widget moves in cross direction depending on whether
  /// it is positive or negative.
  final double crossAxisEndOffset;

  /// Defines pointer types which are allowed to trigger swipe gesture.
  ///
  /// Defaults to {PointerDeviceKind.touch, PointerDeviceKind.invertedStylus, PointerDeviceKind.stylus}
  final Set<PointerDeviceKind> allowedPointerKinds;

  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], the drag gesture used to dismiss a
  /// dismissible will begin upon the detection of a drag gesture. If set to
  /// [DragStartBehavior.down] it will begin when a down event is first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for the different behaviors.
  final DragStartBehavior dragStartBehavior;

  ///If the swipeIntensity is low, the message requires a stronger swipe.
  ///The default value is set to 1. Consider increasing the swipeIntensity to make it easier for users to swipe.
  final double swipeIntensity;

  /// When the user scrolls beyond the maximum offset, the function will be invoked, and it will only be called once.
  final OnOverScrollTheMaxOffset? onOverScrollTheMaxOffset;

  @override
  SwipeableState createState() => SwipeableState();
}

class _SwipeableClipper extends CustomClipper<Rect> {
  _SwipeableClipper({
    required this.moveAnimation,
  }) : super(reclip: moveAnimation);

  final Animation<Offset> moveAnimation;

  @override
  Rect getClip(Size size) {
    final offset = moveAnimation.value.dx * size.width;
    if (offset < 0) {
      return Rect.fromLTRB(size.width + offset, 0.0, size.width, size.height);
    }
    return Rect.fromLTRB(0.0, 0.0, offset, size.height);
  }

  @override
  Rect getApproximateClipRect(Size size) => getClip(size);

  @override
  bool shouldReclip(_SwipeableClipper oldClipper) {
    return oldClipper.moveAnimation.value != moveAnimation.value;
  }
}

enum _FlingGestureKind { none, forward, reverse }

class SwipeableState extends State<Swipeable>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    _moveController =
        AnimationController(duration: widget.movementDuration, vsync: this)
          ..addStatusListener(_handleDismissStatusChanged);
    _updateMoveAnimation();
    _moveController.addListener(listenMoveController);

    super.initState();
  }

  void listenMoveController() {
    if (!isInSwipe) {
      isSwipeAnimationRunning = true;
    }

    if (isSwipeAnimationRunning && _moveController.value >= widget.maxOffset) {
      if (widget.onOverScrollTheMaxOffset != null) {
        widget.onOverScrollTheMaxOffset!();
      }
      isSwipeAnimationRunning = false;
    }
  }

  late AnimationController _moveController;
  late Animation<Offset> _moveAnimation;

  double _dragExtent = 0.0;
  bool isSwipeAnimationRunning = false;
  bool _dragUnderway = false;
  Size? _sizePriorToCollapse;

  bool _isTouch = true;

  @override
  bool get wantKeepAlive => _moveController.isAnimating == true;

  bool get isInSwipe => _moveController.value != 0;

  @override
  void dispose() {
    _moveController.removeStatusListener(_handleDismissStatusChanged);
    _moveController.removeListener(listenMoveController);
    _moveController.dispose();
    super.dispose();
  }

  SwipeDirection _extentToDirection(double extent) {
    if (extent == 0.0) {
      return SwipeDirection.none;
    }
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        return extent < 0
            ? SwipeDirection.startToEnd
            : SwipeDirection.endToStart;
      case TextDirection.ltr:
        return extent > 0
            ? SwipeDirection.startToEnd
            : SwipeDirection.endToStart;
    }
  }

  SwipeDirection get _swipeDirection => _extentToDirection(_dragExtent);

  bool get _isActive {
    return _dragUnderway || _moveController.isAnimating;
  }

  double get _overallDragAxisExtent {
    final size = context.size;
    return size?.width ?? 0.0;
  }

  void _handlePointerDown(PointerDownEvent event) {
    setState(() {
      _isTouch = widget.allowedPointerKinds.contains(event.kind);
    });
  }

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    if (_moveController.isAnimating) {
      _dragExtent =
          _moveController.value * _overallDragAxisExtent * _dragExtent.sign;
      _moveController.stop();
    } else {
      _dragExtent = 0.0;
      _moveController.value = 0.0;
    }
    setState(() {
      _updateMoveAnimation();
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isActive || _moveController.isAnimating) {
      return;
    }

    final delta = (details.primaryDelta ?? 0.0) * widget.swipeIntensity;
    final oldDragExtent = _dragExtent;
    switch (widget.direction) {
      case SwipeDirection.none:
        return;

      case SwipeDirection.horizontal:
        _dragExtent += delta;
        break;

      case SwipeDirection.endToStart:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta > 0) {
              _dragExtent += delta;
            }
            break;
          case TextDirection.ltr:
            if (_dragExtent + delta < 0) {
              _dragExtent += delta;
            }
            break;
        }
        break;

      case SwipeDirection.startToEnd:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta < 0) {
              _dragExtent += delta;
            }
            break;
          case TextDirection.ltr:
            if (_dragExtent + delta > 0) {
              _dragExtent += delta;
            }
            break;
        }
        break;
    }
    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(() {
        _updateMoveAnimation();
      });
    }
    if (!_moveController.isAnimating) {
      _moveController.value = _dragExtent.abs() / _overallDragAxisExtent;
    }
  }

  void _updateMoveAnimation() {
    final end = _dragExtent.sign;
    _moveAnimation = _moveController.drive(
      Tween<Offset>(
        begin: Offset.zero,
        end: Offset(widget.maxOffset * end, widget.crossAxisEndOffset),
      ),
    );
  }

  _FlingGestureKind _describeFlingGesture(Velocity velocity) {
    if (_dragExtent == 0.0) {
      // If it was a fling, then it was a fling that was let loose at the exact
      // middle of the range (i.e. when there's no displacement). In that case,
      // we assume that the user meant to fling it back to the center, as
      // opposed to having wanted to drag it out one way, then fling it past the
      // center and into and out the other side.
      return _FlingGestureKind.none;
    }
    final vx = velocity.pixelsPerSecond.dx;
    final vy = velocity.pixelsPerSecond.dy;
    SwipeDirection flingDirection;
    // Verify that the fling is in the generally right direction and fast enough.
    if (vx.abs() - vy.abs() < _kMinFlingVelocityDelta ||
        vx.abs() < _kMinFlingVelocity) {
      return _FlingGestureKind.none;
    }
    assert(vx != 0.0);
    flingDirection = _extentToDirection(vx);

    if (flingDirection == _swipeDirection) {
      return _FlingGestureKind.forward;
    }
    return _FlingGestureKind.reverse;
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    if (!_isActive || _moveController.isAnimating) {
      return;
    }
    _dragUnderway = false;
    if (_moveController.value >= widget.maxOffset &&
        await _confirmStartSwipeAnimation() == true) {
      _startSwipeAnimation();
      return;
    }
    final flingVelocity = details.velocity.pixelsPerSecond.dx;
    switch (_describeFlingGesture(details.velocity)) {
      case _FlingGestureKind.forward:
        assert(_dragExtent != 0.0);
        assert(!_moveController.isDismissed);
        if ((widget.dismissThresholds[_swipeDirection] ?? _kDismissThreshold) >=
            1.0) {
          await _moveController.reverse();
          break;
        }
        _dragExtent = flingVelocity.sign;
        await _moveController.fling(
          velocity: flingVelocity.abs() * _kFlingVelocityScale,
        );
        break;
      case _FlingGestureKind.reverse:
        assert(_dragExtent != 0.0);
        assert(!_moveController.isDismissed);
        _dragExtent = flingVelocity.sign;
        await _moveController.fling(
          velocity: -flingVelocity.abs() * _kFlingVelocityScale,
        );
        break;
      case _FlingGestureKind.none:
        if (!_moveController.isDismissed) {
          await _moveController.reverse();
        }
        break;
    }
  }

  Future<void> _handleDismissStatusChanged(AnimationStatus status) async {
    if (status == AnimationStatus.completed && !_dragUnderway) {
      if (await _confirmStartSwipeAnimation() == true) {
        _startSwipeAnimation();
      } else {
        await _moveController.reverse();
      }
    }
    updateKeepAlive();
  }

  Future<bool> _confirmStartSwipeAnimation() async {
    if (widget.confirmSwipe != null) {
      final direction = _swipeDirection;
      return widget.confirmSwipe!(direction);
    }
    return true;
  }

  void _startSwipeAnimation() {
    assert(_sizePriorToCollapse == null);

    final direction = _swipeDirection;
    widget.onSwipe(direction);

    _moveController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.

    assert(debugCheckHasDirectionality(context));

    var background = widget.background;
    if (widget.secondaryBackground != null) {
      final direction = _swipeDirection;
      if (direction == SwipeDirection.endToStart) {
        background = widget.secondaryBackground;
      }
    }

    Widget content = SlideTransition(
      position: _moveAnimation,
      child: widget.child,
    );

    if (background != null) {
      content = Stack(
        children: <Widget>[
          if (!_moveAnimation.isDismissed)
            Positioned.fill(
              child: ClipRect(
                clipper: _SwipeableClipper(
                  moveAnimation: _moveAnimation,
                ),
                child: background,
              ),
            ),
          content,
        ],
      );
    }
    // We are not swiping but we may be being dragging in widget.direction.
    return Listener(
      onPointerDown: _handlePointerDown,
      child: GestureDetector(
        onHorizontalDragStart: _isTouch ? _handleDragStart : null,
        onHorizontalDragUpdate: _isTouch ? _handleDragUpdate : null,
        onHorizontalDragEnd: _isTouch ? _handleDragEnd : null,
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: widget.dragStartBehavior,
        child: content,
      ),
    );
  }
}
