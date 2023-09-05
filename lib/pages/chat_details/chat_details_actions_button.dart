import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatDetailsActionsButton extends StatelessWidget {
  final String title;

  final double? width;

  final IconData? iconData;

  final double? iconSize;

  final double? borderRadius;

  final BorderSide? borderSide;

  final EdgeInsetsDirectional? padding;

  final Color? buttonColor;

  final Color? iconColor;

  final OnTapIconButtonCallbackAction? onTap;

  const ChatDetailsActionsButton({
    super.key,
    required this.title,
    this.width,
    this.iconData,
    this.iconSize,
    this.borderRadius,
    this.borderSide,
    this.padding,
    this.buttonColor,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        child: Container(
          width: width,
          padding: padding ?? const EdgeInsetsDirectional.all(8),
          decoration: ShapeDecoration(
            color: buttonColor,
            shape: RoundedRectangleBorder(
              side: borderSide ??
                  BorderSide(
                    width: 0.50,
                    color: LinagoraRefColors.material().neutral[90]!,
                  ),
              borderRadius: BorderRadius.circular(borderRadius ?? 16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (iconData != null)
                Icon(
                  iconData,
                  size: iconSize ?? 24,
                  color: iconColor,
                ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
