import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  final VoidCallback? onPressed;

  const TwakeIconButton({
    Key? key, 
    required this.tooltip,
    this.onPressed,
    this.icon, 
    this.imagePath,
    this.paddingAll,
    this.size, 
    this.fill, 
    this.weight, 
    this.margin = const EdgeInsets.all(0),
    this.buttonDecoration,
  }): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: margin,
      decoration: buttonDecoration ?? const BoxDecoration(shape: BoxShape.circle),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        radius: paddingAll,
        child: Tooltip(
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
    );
  }

}