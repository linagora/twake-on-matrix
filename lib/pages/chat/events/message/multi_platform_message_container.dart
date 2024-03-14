import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class MultiPlatformsMessageContainer extends StatelessWidget {
  final void Function()? onTap;

  final Function(bool) onHover;

  final Widget child;

  const MultiPlatformsMessageContainer({
    super.key,
    this.onTap,
    required this.onHover,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformInfos.isWeb) {
      return MouseRegion(
        child: child,
        onHover: (event) {
          onHover(true);
        },
        onExit: (event) {
          onHover(false);
        },
      );
    }
    return InkWell(
      hoverColor: Colors.transparent,
      onTap: onTap,
      onHover: (hover) {
        onHover(hover);
      },
      child: child,
    );
  }
}

class MultiPlatformSelectionMode extends StatelessWidget {
  final void Function(Event event)? onLongPress;

  final Event event;

  final Widget child;

  final bool isClickable;

  const MultiPlatformSelectionMode({
    super.key,
    this.onLongPress,
    this.isClickable = true,
    required this.event,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isClickable) {
      return child;
    }

    return GestureDetector(
      onLongPress: () => onLongPress?.call(event),
      child: child,
    );
  }
}
