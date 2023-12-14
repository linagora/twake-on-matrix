// reference to: https://pub.dev/packages/contextmenu
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'twake_context_menu.dart';

typedef ContextMenuBuilder = List<Widget> Function(BuildContext context);

/// Show a [TwakeContextMenu] on the given [BuildContext]. For other parameters, see [TwakeContextMenu].
void showTwakeContextMenu(
  Offset offset,
  BuildContext context,
  ContextMenuBuilder builder,
  verticalPadding,
  width,
) {
  showModal(
    context: context,
    configuration: const FadeScaleTransitionConfiguration(
      barrierColor: Colors.transparent,
    ),
    builder: (context) => TwakeContextMenu(
      position: offset,
      builder: builder,
      verticalPadding: verticalPadding,
      width: width,
    ),
  );
}

/// The [TwakeContextMenuArea] is the way to use a [TwakeContextMenu]
///
/// It listens for right click and long press and executes [showTwakeContextMenu]
/// with the corresponding location [Offset].

class TwakeContextMenuArea extends StatelessWidget {
  /// The widget displayed inside the [TwakeContextMenuArea]
  final Widget child;

  /// Builds a [List] of items to be displayed in an opened [TwakeContextMenu]
  ///
  /// Usually, a [ListTile] might be the way to go.
  final ContextMenuBuilder? builder;

  /// The padding value at the top an bottom between the edge of the [TwakeContextMenu] and the first / last item
  final double verticalPadding;

  /// The width for the [TwakeContextMenu]. 320 by default according to Material Design specs.
  final double width;

  const TwakeContextMenuArea({
    Key? key,
    required this.child,
    this.builder,
    this.verticalPadding = 8,
    this.width = 320,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (builder == null) {
      return child;
    }
    return GestureDetector(
      onSecondaryTapDown: (details) => showTwakeContextMenu(
        details.globalPosition,
        context,
        builder!,
        verticalPadding,
        width,
      ),
      child: child,
    );
  }
}
