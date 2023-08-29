import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

typedef OnTapIconButtonCallbackAction = void Function();
typedef OnTapDownIconButtonCallbackAction = void Function(
  BuildContext,
);

class TwakeIconButton extends StatelessWidget {
  final BoxDecoration? buttonDecoration;

  final IconData? icon;

  final String? imagePath;

  final String tooltip;

  final EdgeInsets margin;

  final double? paddingAll;

  final double? size;

  final double? fill;

  final double? weight;

  final OnTapIconButtonCallbackAction? onTap;

  final OnTapDownIconButtonCallbackAction? onTapDown;

  final bool? preferBelow;

  final Color? hoverColor;

  const TwakeIconButton({
    Key? key,
    required this.tooltip,
    this.onTap,
    this.icon,
    this.imagePath,
    this.paddingAll,
    this.size,
    this.fill,
    this.weight,
    this.preferBelow,
    this.hoverColor,
    this.onTapDown,
    this.margin = const EdgeInsets.all(0),
    this.buttonDecoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: margin,
        decoration:
            buttonDecoration ?? const BoxDecoration(shape: BoxShape.circle),
        child: InkWell(
          onTap: onTap,
          onTapDown: (_) => onTapDown?.call(context),
          customBorder: const CircleBorder(),
          radius: paddingAll,
          hoverColor: hoverColor,
          child: Tooltip(
            preferBelow: preferBelow,
            message: tooltip,
            child: Padding(
              padding: EdgeInsets.all(paddingAll ?? 8.0),
              child: icon != null
                  ? Icon(
                      icon,
                      size: size,
                      fill: fill,
                      weight: weight,
                    )
                  : imagePath != null
                      ? SvgPicture.asset(imagePath!)
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}
