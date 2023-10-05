import 'package:fluffychat/utils/custom_dismissable.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';

/// A callback for the [InteractiveViewerBoundary] that is called when the scale
/// changed.
typedef ScaleChanged = void Function(double scale);

/// Builds an [InteractiveViewer] and provides callbacks that are called when a
/// horizontal boundary has been hit.
///
/// The callbacks are called when an interaction ends by listening to the
/// [InteractiveViewer.onInteractionEnd] callback.
class InteractiveViewerGallery extends StatefulWidget {
  const InteractiveViewerGallery({
    super.key,
    required this.itemBuilder,
    this.maxScale = 2.5,
    this.minScale = 1.0,
    this.handleDragStart,
    this.handleDragEnd,
  });

  /// The item content
  final Widget itemBuilder;

  final double maxScale;

  final double minScale;

  final Function(DragStartDetails dragStartDetails)? handleDragStart;

  final Function(DragEndDetails dragEndDetails)? handleDragEnd;

  @override
  State<InteractiveViewerGallery> createState() =>
      _InteractiveViewerGalleryState();
}

class _InteractiveViewerGalleryState extends State<InteractiveViewerGallery>
    with SingleTickerProviderStateMixin {
  TransformationController? _transformationController;

  /// The controller to animate the transformation value of the
  /// [InteractiveViewer] when it should reset.
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  /// `true` when an source is zoomed in to disable the [CustomDismissible].
  bool _enableDismiss = true;

  @override
  void initState() {
    super.initState();

    _transformationController = TransformationController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )
      ..addListener(() {
        _transformationController!.value =
            _animation?.value ?? Matrix4.identity();
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed && !_enableDismiss) {
          setState(() {
            _enableDismiss = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomDismissible(
      onDismissed: () => Navigator.of(context).pop(),
      enabled: _enableDismiss && !PlatformInfos.isWeb,
      child: widget.itemBuilder,
    );
  }
}
