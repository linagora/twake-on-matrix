import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A custom scrollbar for bidirectional scroll views on Flutter web.
///
/// Flutter's built-in [Scrollbar] has a hard requirement that
/// [ScrollPosition.maxScrollExtent] > 0 before registering any gesture
/// recognizers. Our chat uses [CustomScrollView] with [anchor] = 1 and a
/// [center] key, which stores all past messages *before* the center sliver,
/// resulting in [minScrollExtent] < 0 and [maxScrollExtent] ≈ 0.
///
/// This widget computes the total scrollable extent as
/// `maxScrollExtent - minScrollExtent` and enables thumb drag whenever that
/// value is positive, regardless of the sign of [maxScrollExtent].
class ChatWebScrollbar extends StatefulWidget {
  const ChatWebScrollbar({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<ChatWebScrollbar> createState() => _ChatWebScrollbarState();
}

class _ChatWebScrollbarState extends State<ChatWebScrollbar> {
  static const double _thumbWidth = 8.0;
  static const double _minThumbHeight = 48.0;
  static const double _thumbPadding = 2.0;

  bool _isDragging = false;
  bool _isThumbHovered = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScrollPositionChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScrollPositionChanged);
    super.dispose();
  }

  void _onScrollPositionChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasScrollableContent {
    if (!widget.controller.hasClients) return false;
    final position = widget.controller.position;
    if (!position.hasContentDimensions) return false;
    return (position.maxScrollExtent - position.minScrollExtent) > 0;
  }

  /// Computes thumb [top] offset and [height] within a track of [trackHeight].
  ({double top, double height}) _thumbMetrics(double trackHeight) {
    final position = widget.controller.position;
    final totalExtent = position.maxScrollExtent - position.minScrollExtent;

    // Thumb height proportional to viewport vs total content
    final viewportFraction =
        position.viewportDimension / (position.viewportDimension + totalExtent);
    final thumbHeight = (viewportFraction * trackHeight).clamp(
      _minThumbHeight,
      trackHeight,
    );

    // Thumb position proportional to current scroll offset
    final scrollFraction =
        (position.pixels - position.minScrollExtent) / totalExtent;
    final thumbTop = scrollFraction * (trackHeight - thumbHeight);

    return (
      top: thumbTop.clamp(0.0, trackHeight - thumbHeight),
      height: thumbHeight,
    );
  }

  void _onThumbDragUpdate(DragUpdateDetails details, double trackHeight) {
    if (!widget.controller.hasClients) return;
    final position = widget.controller.position;
    final totalExtent = position.maxScrollExtent - position.minScrollExtent;
    if (totalExtent <= 0) return;

    final scrollableTrackHeight =
        trackHeight - _thumbMetrics(trackHeight).height;
    if (scrollableTrackHeight <= 0) return;

    final pixelDelta = (details.delta.dy / scrollableTrackHeight) * totalExtent;
    final newPixels = (position.pixels + pixelDelta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    widget.controller.jumpTo(newPixels);
  }

  void _onTrackTap(TapUpDetails details, double trackHeight) {
    if (!widget.controller.hasClients) return;
    final position = widget.controller.position;
    final totalExtent = position.maxScrollExtent - position.minScrollExtent;
    if (totalExtent <= 0) return;

    final tapFraction = details.localPosition.dy / trackHeight;
    final targetPixels = position.minScrollExtent + tapFraction * totalExtent;
    widget.controller.animateTo(
      targetPixels.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // NotificationListener catches the initial ScrollMetricsNotification that
    // fires after the first layout, triggering a rebuild so the thumb appears
    // without requiring the user to scroll first.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        if (mounted) setState(() {});
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (_hasScrollableContent) _buildScrollbarTrack(context),
        ],
      ),
    );
  }

  Widget _buildScrollbarTrack(BuildContext context) {
    final thumbColor = Theme.of(context).colorScheme.onSurface.withValues(
      alpha: _isDragging
          ? 0.8
          : _isThumbHovered
          ? 0.6
          : 0.4,
    );

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: _thumbWidth + _thumbPadding * 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackHeight = constraints.maxHeight;
          final metrics = _thumbMetrics(trackHeight);

          return Listener(
            // Forward wheel/trackpad scroll events so they reach the
            // underlying scrollable even when the pointer is over the gutter.
            onPointerSignal: (event) {
              if (event is PointerScrollEvent && widget.controller.hasClients) {
                final position = widget.controller.position;
                final newPixels = (position.pixels + event.scrollDelta.dy)
                    .clamp(position.minScrollExtent, position.maxScrollExtent);
                widget.controller.jumpTo(newPixels);
              }
            },
            child: GestureDetector(
              // translucent so pointer signals can still reach widgets below
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) => _onTrackTap(details, trackHeight),
              child: Stack(
                children: [
                  Positioned(
                    top: metrics.top,
                    right: _thumbPadding,
                    width: _thumbWidth,
                    height: metrics.height,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      onEnter: (_) => setState(() => _isThumbHovered = true),
                      onExit: (_) => setState(() => _isThumbHovered = false),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragStart: (_) =>
                            setState(() => _isDragging = true),
                        onVerticalDragUpdate: (details) =>
                            _onThumbDragUpdate(details, trackHeight),
                        onVerticalDragEnd: (_) =>
                            setState(() => _isDragging = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: thumbColor,
                            borderRadius: BorderRadius.circular(
                              _thumbWidth / 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
