import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

typedef OnTapIconButtonCallbackAction = void Function();
typedef OnTapDownIconButtonCallbackAction = void Function(
  TapDownDetails,
);

class TwakeIconButton extends StatelessWidget {
  final BoxDecoration? buttonDecoration;

  final IconData? icon;

  final String? imagePath;

  final double? imageSize;

  final String? tooltip;

  final EdgeInsets margin;

  final double? paddingAll;

  final double? size;

  final double? fill;

  final double? weight;

  final OnTapIconButtonCallbackAction? onTap;

  final OnTapDownIconButtonCallbackAction? onTapDown;

  final bool? preferBelow;

  final Color? hoverColor;

  final Color? iconColor;

  final Color? highlightColor;

  final Color? splashColor;

  const TwakeIconButton({
    super.key,
    this.tooltip,
    this.onTap,
    this.icon,
    this.imagePath,
    this.imageSize,
    this.paddingAll,
    this.size,
    this.fill,
    this.weight,
    this.preferBelow,
    this.hoverColor,
    this.onTapDown,
    this.margin = const EdgeInsets.all(0),
    this.buttonDecoration,
    this.iconColor,
    this.highlightColor,
    this.splashColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: margin,
        decoration:
            buttonDecoration ?? const BoxDecoration(shape: BoxShape.circle),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: onTap,
          onTapDown: onTapDown != null
              ? (tapDownDetails) => onTapDown!.call(tapDownDetails)
              : null,
          customBorder: const CircleBorder(),
          radius: paddingAll,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          child: TooltipVisibility(
            visible: tooltip != null ? true : false,
            child: Tooltip(
              showDuration: const Duration(seconds: 1),
              waitDuration: const Duration(seconds: 1),
              preferBelow: preferBelow,
              message: tooltip ?? "",
              child: Padding(
                padding: EdgeInsets.all(paddingAll ?? 8.0),
                child: icon != null
                    ? Icon(
                        icon,
                        size: size,
                        fill: fill,
                        weight: weight,
                        color: iconColor,
                      )
                    : imagePath != null
                        ? SvgPicture.asset(
                            imagePath!,
                            height: imageSize,
                            width: imageSize,
                            colorFilter: iconColor != null
                                ? ColorFilter.mode(
                                    iconColor!,
                                    BlendMode.srcIn,
                                  )
                                : null,
                          )
                        : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
