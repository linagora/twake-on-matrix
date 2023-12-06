import 'package:fluffychat/pages/chat/events/message/message_style.dart';
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
  final bool longPressSelect;

  final void Function(Event event)? onSelect;

  final Event event;

  final Widget child;

  final bool useInkWell;

  const MultiPlatformSelectionMode({
    super.key,
    required this.longPressSelect,
    this.onSelect,
    this.useInkWell = true,
    required this.event,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!useInkWell) {
      return child;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: MessageStyle.bubbleBorderRadius,
      borderOnForeground: false,
      child: InkWell(
        onTap: () => onSelect?.call(event),
        onLongPress: !longPressSelect ? null : () => onSelect?.call(event),
        borderRadius: MessageStyle.bubbleBorderRadius,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: child,
      ),
    );
  }
}
