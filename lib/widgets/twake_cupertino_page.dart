import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

// Copied from flutter/src/cupertino/route.dart (private constants).
const double _kMinFlingVelocity = 1.0;
const Duration _kDroppedSwipePageAnimationDuration = Duration(
  milliseconds: 350,
);

/// A [Page] that creates an iOS-style [PageRoute] with a configurable
/// back-gesture hit-test width.
///
/// Identical to [CupertinoPage] but exposes [backGestureWidth] so callers can
/// widen the swipe-back target area beyond the default 20 logical pixels.
class TwakeCupertinoPage<T> extends Page<T> {
  const TwakeCupertinoPage({
    required this.child,
    this.maintainState = true,
    this.title,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
    this.backGestureWidth = 20.0,
    super.canPop,
    super.onPopInvoked,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : assert(
         backGestureWidth >= 0 && backGestureWidth < double.infinity,
         'backGestureWidth must be a finite, non-negative value',
       );

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.cupertino.CupertinoRouteTransitionMixin.title}
  final String? title;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  /// {@macro flutter.widgets.PageRoute.fullscreenDialog}
  final bool fullscreenDialog;

  /// {@macro flutter.widgets.TransitionRoute.allowSnapshotting}
  final bool allowSnapshotting;

  /// Width of the interactive pop gesture hit area in logical pixels.
  ///
  /// The system default ([CupertinoPage]) uses 20 px. Increase this value to
  /// make the edge swipe easier to trigger on devices with minimal bezel or
  /// with a screen protector.
  final double backGestureWidth;

  @override
  Route<T> createRoute(BuildContext context) {
    return _TwakePageBasedCupertinoPageRoute<T>(
      page: this,
      allowSnapshotting: allowSnapshotting,
    );
  }
}

// ---------------------------------------------------------------------------
// Route
// ---------------------------------------------------------------------------

class _TwakePageBasedCupertinoPageRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  _TwakePageBasedCupertinoPageRoute({
    required TwakeCupertinoPage<T> page,
    super.allowSnapshotting = true,
  }) : super(settings: page) {
    assert(opaque);
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      fullscreenDialog ? null : CupertinoPageTransition.delegatedTransition;

  TwakeCupertinoPage<T> get _page => settings as TwakeCupertinoPage<T>;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  String? get title => _page.title;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  /// Starts the pop gesture and returns the controller.
  _TwakeCupertinoBackGestureController<T> _startPopGesture() {
    assert(popGestureEnabled);
    return _TwakeCupertinoBackGestureController<T>(
      navigator: navigator!,
      getIsCurrent: () => isCurrent,
      getIsActive: () => isActive,
      controller: controller!,
    );
  }

  /// Replaces [CupertinoRouteTransitionMixin.buildTransitions] so we can
  /// inject [_TwakeCupertinoBackGestureDetector] with the custom width.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final bool linearTransition = popGestureInProgress;
    if (fullscreenDialog) {
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: child,
      );
    }
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: linearTransition,
      child: _TwakeCupertinoBackGestureDetector<T>(
        backGestureWidth: _page.backGestureWidth,
        enabledCallback: () => popGestureEnabled,
        onStartPopGesture: _startPopGesture,
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gesture detector — copy of _CupertinoBackGestureDetector with configurable
// backGestureWidth instead of the hardcoded _kBackGestureWidth = 20.0.
// Sourced from Flutter 3.38.9 (flutter/lib/src/cupertino/route.dart).
// Keep in sync when upgrading Flutter.
// ---------------------------------------------------------------------------

class _TwakeCupertinoBackGestureDetector<T> extends StatefulWidget {
  const _TwakeCupertinoBackGestureDetector({
    super.key,
    required this.backGestureWidth,
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
  });

  final double backGestureWidth;
  final Widget child;
  final ValueGetter<bool> enabledCallback;
  final ValueGetter<_TwakeCupertinoBackGestureController<T>> onStartPopGesture;

  @override
  _TwakeCupertinoBackGestureDetectorState<T> createState() =>
      _TwakeCupertinoBackGestureDetectorState<T>();
}

class _TwakeCupertinoBackGestureDetectorState<T>
    extends State<_TwakeCupertinoBackGestureDetector<T>> {
  _TwakeCupertinoBackGestureController<T>? _backGestureController;

  late HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    final controller = _backGestureController;
    _backGestureController = null;
    if (controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.navigator.mounted) {
          controller.navigator.didStopUserGesture();
        }
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_backGestureController == null);
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    final size = context.size;
    if (size == null) return;
    _backGestureController!.dragUpdate(
      _convertToLogical(details.primaryDelta! / size.width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    final size = context.size;
    if (size == null) {
      _backGestureController?.dragEnd(0.0);
      _backGestureController = null;
      return;
    }
    _backGestureController!.dragEnd(
      _convertToLogical(details.velocity.pixelsPerSecond.dx / size.width),
    );
    _backGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) {
      _recognizer.addPointer(event);
    }
  }

  double _convertToLogical(double value) {
    return switch (Directionality.of(context)) {
      TextDirection.rtl => -value,
      TextDirection.ltr => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final double dragAreaWidth = switch (Directionality.of(context)) {
      TextDirection.rtl => MediaQuery.paddingOf(context).right,
      TextDirection.ltr => MediaQuery.paddingOf(context).left,
    };
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          start: 0.0,
          width: max(dragAreaWidth, widget.backGestureWidth),
          top: 0.0,
          bottom: 0.0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gesture controller — identical copy of _CupertinoBackGestureController.
// Must be copied because it's private in the Flutter SDK.
// ---------------------------------------------------------------------------

class _TwakeCupertinoBackGestureController<T> {
  _TwakeCupertinoBackGestureController({
    required this.navigator,
    required this.controller,
    required this.getIsActive,
    required this.getIsCurrent,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;

  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  void dragEnd(double velocity) {
    const Curve animationCurve = Curves.fastEaseInToSlowEaseOut;
    final bool isCurrent = getIsCurrent();
    final bool animateForward;

    if (!isCurrent) {
      animateForward = getIsActive();
    } else if (velocity.abs() >= _kMinFlingVelocity) {
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      controller.animateTo(
        1.0,
        duration: _kDroppedSwipePageAnimationDuration,
        curve: animationCurve,
      );
    } else {
      if (isCurrent) {
        navigator.pop();
      }
      if (controller.isAnimating) {
        controller.animateBack(
          0.0,
          duration: _kDroppedSwipePageAnimationDuration,
          curve: animationCurve,
        );
      }
    }

    if (controller.isAnimating) {
      late AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
