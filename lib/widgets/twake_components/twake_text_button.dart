import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TwakeTextButton extends StatelessWidget {
  final BoxDecoration? buttonDecoration;

  final String message;

  final EdgeInsetsDirectional margin;

  final TextStyle? styleMessage;

  final double? paddingAll;

  final double? size;

  final double? fill;

  final double? weight;

  final OnTapIconButtonCallbackAction? onTap;

  final OnTapDownIconButtonCallbackAction? onTapDown;

  final bool? preferBelow;

  final Color? hoverColor;

  final double? borderHover;

  const TwakeTextButton({
    super.key,
    required this.message,
    this.styleMessage,
    this.onTap,
    this.paddingAll,
    this.size,
    this.fill,
    this.weight,
    this.preferBelow,
    this.hoverColor,
    this.onTapDown,
    this.margin = const EdgeInsetsDirectional.all(0),
    this.buttonDecoration,
    this.borderHover,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        onTapDown: (tapDownDetails) => onTapDown?.call(tapDownDetails),
        radius: paddingAll,
        hoverColor: hoverColor,
        borderRadius: BorderRadius.circular(borderHover ?? 0),
        child: Container(
          padding: margin,
          decoration:
              buttonDecoration ?? const BoxDecoration(shape: BoxShape.circle),
          child: Tooltip(
            preferBelow: preferBelow,
            message: message,
            child: Padding(
              padding: EdgeInsets.all(paddingAll ?? 8.0),
              child: Text(
                message,
                style: styleMessage ??
                    Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: LinagoraSysColors.material().onPrimary,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
