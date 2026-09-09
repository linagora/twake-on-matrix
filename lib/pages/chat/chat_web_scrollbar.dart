import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A custom scrollbar for bidirectional scroll views on Flutter web.
///
/// Flutter's built-in [Scrollbar] / [RawScrollbar] paint path already supports
/// bidirectional extents (`maxScrollExtent - minScrollExtent`), but on Flutter
/// 3.38.x (this app's current SDK) gesture registration still gates on
/// `maxScrollExtent > 0`. Our chat uses [CustomScrollView] with [anchor] = 1
/// and a [center] key, so past messages live before the center sliver:
/// `minScrollExtent < 0` and `maxScrollExtent ≈ 0`. Stock gestures never arm.
/// (Fixed upstream in Flutter 3.41+ / #179199.)
///
/// Architecture (same ideas as [RawScrollbar], isolated for chat web):
/// - Thumb updates via [ScrollbarPainter] → **repaint only**, never rebuilds
///   the message list.
/// - Painter lives in a **gutter-only** [CustomPaint] overlay (not wrapping
///   the chat). Full-size [CustomPaint] over the list re-composites the whole
///   surface every scroll frame on Flutter web and reads as blink/flash.
/// - [child] sits in its own layer; scroll never calls [setState] on this
///   State except when gesture enablement flips (scrollable ↔ not).
/// - Wheel over the gutter uses [ScrollPosition.pointerScroll].
///
/// Thumb drag maps absolute pointer→track position to
/// `minScrollExtent + fraction * (max - min)`. Flutter's
/// [ScrollbarPainter.getThumbScrollOffset] assumes a 0-based extent and is
/// wrong for reverse/center viewports.
class ChatWebScrollbar extends StatefulWidget {
  const ChatWebScrollbar({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<ChatWebScrollbar> createState() => ChatWebScrollbarState();
}

/// Public state so widget tests can resolve the painter hit area.
class ChatWebScrollbarState extends State<ChatWebScrollbar>
    with TickerProviderStateMixin {
  static const double _thumbThickness = 8.0;
  static const double _minThumbLength = 48.0;
  static const double _crossAxisMargin = 2.0;
  static const double _gutterWidth = _thumbThickness + _crossAxisMargin * 2;

  final GlobalKey _painterKey = GlobalKey();

  late final AnimationController _opacityController;
  late final ScrollbarPainter _painter;

  /// Gestures are only registered while a single position is scrollable.
  /// Flipping this is the only scroll-related [setState] — not per pixel.
  bool _gesturesEnabled = false;

  bool _isDragging = false;
  bool _isThumbHovered = false;

  /// Track-local Y where the drag started.
  double? _dragStartLocalY;

  /// Thumb top (track-local) frozen at drag start.
  double? _dragStartThumbTop;

  @override
  void initState() {
    super.initState();
    // Always-visible thumb for chat (no fade-out timer).
    _opacityController = AnimationController(vsync: this, value: 1.0);
    _painter = ScrollbarPainter(
      color: const Color(0x66000000),
      fadeoutOpacityAnimation: _opacityController,
      thickness: _thumbThickness,
      radius: const Radius.circular(_thumbThickness / 2),
      // Gutter [CustomPaint] is already the track; do not inset again.
      padding: EdgeInsets.zero,
      crossAxisMargin: _crossAxisMargin,
      mainAxisMargin: _crossAxisMargin,
      minLength: _minThumbLength,
      scrollbarOrientation: ScrollbarOrientation.right,
    );
  }

  @override
  void dispose() {
    _painter.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  /// The single attached [ScrollPosition], or `null` when the controller has
  /// zero or more than one attached scroll view.
  ScrollPosition? get _attachedPosition {
    final controller = widget.controller;
    if (controller.positions.length != 1) return null;
    return controller.position;
  }

  bool _isScrollable(ScrollMetrics metrics) {
    return metrics.maxScrollExtent - metrics.minScrollExtent >
        precisionErrorTolerance;
  }

  void _configurePainterFromTheme() {
    final base = Theme.of(context).colorScheme.onSurface;
    final alpha = _isDragging
        ? 0.8
        : _isThumbHovered
        ? 0.6
        : 0.4;
    _painter
      ..color = base.withValues(alpha: alpha)
      ..textDirection = Directionality.of(context)
      ..padding = EdgeInsets.zero;
  }

  void _syncGesturesEnabled(ScrollMetrics metrics) {
    final enabled =
        _attachedPosition != null &&
        metrics.hasContentDimensions &&
        _isScrollable(metrics);
    if (enabled == _gesturesEnabled) return;
    setState(() => _gesturesEnabled = enabled);
  }

  bool _shouldUpdatePainter(Axis notificationAxis) {
    final controller = widget.controller;
    if (controller.positions.length > 1) return false;
    if (!controller.hasClients) return true;
    return controller.position.axis == notificationAxis;
  }

  bool _handleScrollMetricsNotification(
    ScrollMetricsNotification notification,
  ) {
    final metrics = notification.metrics;
    if (_shouldUpdatePainter(metrics.axis)) {
      _painter.update(metrics, metrics.axisDirection);
    }
    _syncGesturesEnabled(metrics);
    return false;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (!_isScrollable(metrics)) {
      if (_shouldUpdatePainter(metrics.axis)) {
        _painter.update(metrics, metrics.axisDirection);
      }
      _syncGesturesEnabled(metrics);
      return false;
    }

    if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification ||
        notification is ScrollEndNotification) {
      if (_shouldUpdatePainter(metrics.axis)) {
        _painter.update(metrics, metrics.axisDirection);
      }
    }
    _syncGesturesEnabled(metrics);
    return false;
  }

  Offset _globalToLocal(Offset globalPosition) {
    final box = _painterKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return globalPosition;
    return box.globalToLocal(globalPosition);
  }

  bool _isOverThumb(Offset globalPosition) {
    final local = _globalToLocal(globalPosition);
    return _painter.hitTestOnlyThumbInteractive(local, PointerDeviceKind.mouse);
  }

  bool _isOverTrack(Offset globalPosition) {
    final local = _globalToLocal(globalPosition);
    return _painter.hitTestInteractive(local, PointerDeviceKind.mouse) &&
        !_painter.hitTestOnlyThumbInteractive(local, PointerDeviceKind.mouse);
  }

  /// Thumb top in track coordinates for the current metrics (bidirectional).
  double? _thumbTopForMetrics(ScrollPosition position, double trackExtent) {
    final totalExtent = position.maxScrollExtent - position.minScrollExtent;
    if (totalExtent <= precisionErrorTolerance) return null;

    final viewportFraction =
        position.viewportDimension / (position.viewportDimension + totalExtent);
    final thumbHeight = (viewportFraction * trackExtent).clamp(
      _minThumbLength,
      trackExtent,
    );
    final scrollFraction =
        (position.pixels - position.minScrollExtent) / totalExtent;
    return scrollFraction * (trackExtent - thumbHeight);
  }

  void _onThumbDragStart(DragStartDetails details) {
    final position = _attachedPosition;
    if (position == null) return;

    final box = _painterKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final local = _globalToLocal(details.globalPosition);
    final thumbTop = _thumbTopForMetrics(position, box.size.height);
    if (thumbTop == null) return;

    _isDragging = true;
    _dragStartLocalY = local.dy;
    _dragStartThumbTop = thumbTop;
    _configurePainterFromTheme();
  }

  void _onThumbDragUpdate(DragUpdateDetails details) {
    if (!_isDragging ||
        _dragStartLocalY == null ||
        _dragStartThumbTop == null) {
      return;
    }

    final position = _attachedPosition;
    if (position == null) return;
    final totalExtent = position.maxScrollExtent - position.minScrollExtent;
    if (totalExtent <= precisionErrorTolerance) return;

    final box = _painterKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final trackExtent = box.size.height;
    final viewportFraction =
        position.viewportDimension / (position.viewportDimension + totalExtent);
    final thumbHeight = (viewportFraction * trackExtent).clamp(
      _minThumbLength,
      trackExtent,
    );
    final scrollableTrack = trackExtent - thumbHeight;
    if (scrollableTrack <= precisionErrorTolerance) return;

    final local = _globalToLocal(details.globalPosition);
    final newThumbTop = (_dragStartThumbTop! + (local.dy - _dragStartLocalY!))
        .clamp(0.0, scrollableTrack);
    final newPixels =
        position.minScrollExtent +
        (newThumbTop / scrollableTrack) * totalExtent;

    widget.controller.jumpTo(
      newPixels.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  void _onThumbDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    _dragStartLocalY = null;
    _dragStartThumbTop = null;
    _configurePainterFromTheme();
  }

  void _onThumbDragCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    _dragStartLocalY = null;
    _dragStartThumbTop = null;
    _configurePainterFromTheme();
  }

  void _onTrackTap(TapUpDetails details) {
    if (_isDragging) return;

    final position = _attachedPosition;
    if (position == null) return;
    final totalExtent = position.maxScrollExtent - position.minScrollExtent;
    if (totalExtent <= precisionErrorTolerance) return;

    final box = _painterKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final local = _globalToLocal(details.globalPosition);
    final tapFraction = (local.dy / box.size.height).clamp(0.0, 1.0);
    final targetPixels = position.minScrollExtent + tapFraction * totalExtent;
    widget.controller.animateTo(
      targetPixels.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handleWheelScroll(PointerScrollEvent event, ScrollPosition position) {
    final delta = event.scrollDelta.dy;
    if (delta == 0.0) return;
    if (!position.physics.shouldAcceptUserOffset(position)) return;
    position.pointerScroll(delta);
  }

  void _receivedPointerSignal(PointerSignalEvent event) {
    final position = _attachedPosition;
    if (position == null) return;
    if (event is! PointerScrollEvent) return;

    final local = _globalToLocal(event.position);
    if (!(_painter.hitTest(local) ?? false)) return;

    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (resolved) =>
          _handleWheelScroll(resolved as PointerScrollEvent, position),
    );
  }

  Map<Type, GestureRecognizerFactory> get _gestures {
    if (!_gesturesEnabled) return const <Type, GestureRecognizerFactory>{};

    return <Type, GestureRecognizerFactory>{
      _ThumbDragGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<_ThumbDragGestureRecognizer>(
            () => _ThumbDragGestureRecognizer(
              isThumbHit: _isOverThumb,
              debugOwner: this,
            ),
            (instance) {
              instance
                ..onStart = _onThumbDragStart
                ..onUpdate = _onThumbDragUpdate
                ..onEnd = _onThumbDragEnd
                ..onCancel = _onThumbDragCancel
                ..gestureSettings = const DeviceGestureSettings(touchSlop: 0)
                ..dragStartBehavior = DragStartBehavior.down;
            },
          ),
      _TrackTapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<_TrackTapGestureRecognizer>(
            () => _TrackTapGestureRecognizer(
              isTrackHit: _isOverTrack,
              debugOwner: this,
            ),
            (instance) {
              instance.onTapUp = _onTrackTap;
            },
          ),
    };
  }

  /// Whether the painter currently has a scrollable thumb (tests / debug).
  @visibleForTesting
  bool get debugHasScrollableThumb => _gesturesEnabled;

  /// Global rect approximating the thumb for widget tests.
  @visibleForTesting
  Rect? debugThumbGlobalRect() {
    final position = _attachedPosition;
    final box = _painterKey.currentContext?.findRenderObject() as RenderBox?;
    if (position == null || box == null || !box.hasSize) return null;

    final totalExtent = position.maxScrollExtent - position.minScrollExtent;
    if (totalExtent <= precisionErrorTolerance) return null;

    final trackExtent = box.size.height;
    final viewportFraction =
        position.viewportDimension / (position.viewportDimension + totalExtent);
    final thumbHeight = (viewportFraction * trackExtent).clamp(
      _minThumbLength,
      trackExtent,
    );
    final thumbTop = _thumbTopForMetrics(position, trackExtent);
    if (thumbTop == null) return null;

    final localTopLeft = Offset(
      box.size.width - _thumbThickness - _crossAxisMargin,
      thumbTop,
    );
    final globalTopLeft = box.localToGlobal(localTopLeft);
    return globalTopLeft & Size(_thumbThickness, thumbHeight);
  }

  Widget _buildGutter() {
    return Positioned(
      key: const ValueKey('chat_web_scrollbar_gutter'),
      top: 0,
      right: 0,
      bottom: 0,
      width: _gutterWidth,
      child: Listener(
        onPointerSignal: _receivedPointerSignal,
        child: RawGestureDetector(
          gestures: _gestures,
          child: MouseRegion(
            cursor: _isDragging
                ? SystemMouseCursors.grabbing
                : _isThumbHovered
                ? SystemMouseCursors.grab
                : SystemMouseCursors.basic,
            onHover: (event) {
              final overThumb = _isOverThumb(event.position);
              if (overThumb == _isThumbHovered) return;
              _isThumbHovered = overThumb;
              // Color change repaints the gutter painter only — no setState.
              _configurePainterFromTheme();
              // Cursor still needs a cheap rebuild of this overlay only.
              setState(() {});
            },
            onExit: (_) {
              if (!_isThumbHovered && !_isDragging) return;
              _isThumbHovered = false;
              _configurePainterFromTheme();
              setState(() {});
            },
            child: CustomPaint(
              key: _painterKey,
              // Gutter-only: repaints stay in this ~12px strip, not the chat.
              painter: _painter,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _configurePainterFromTheme();

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleScrollMetricsNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Chat content: never a CustomPaint child, so scrollbar thumb
            // motion cannot re-composite the message surface on web.
            RepaintBoundary(child: widget.child),
            if (_gesturesEnabled) _buildGutter(),
          ],
        ),
      ),
    );
  }
}

class _ThumbDragGestureRecognizer extends VerticalDragGestureRecognizer {
  _ThumbDragGestureRecognizer({
    required this.isThumbHit,
    required super.debugOwner,
  });

  final bool Function(Offset globalPosition) isThumbHit;

  @override
  bool isPointerAllowed(PointerEvent event) {
    return isThumbHit(event.position) && super.isPointerAllowed(event);
  }
}

class _TrackTapGestureRecognizer extends TapGestureRecognizer {
  _TrackTapGestureRecognizer({
    required this.isTrackHit,
    required super.debugOwner,
  });

  final bool Function(Offset globalPosition) isTrackHit;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    return isTrackHit(event.position) && super.isPointerAllowed(event);
  }
}
