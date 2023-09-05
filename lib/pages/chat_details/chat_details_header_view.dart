import 'package:fluffychat/pages/chat_details/chat_details_actions_enum.dart';
import 'package:flutter/material.dart';

import 'chat_details_actions_button.dart';

typedef OnTapIconButtonCallbackAction = Function(ChatDetailsActions);

class ActionsHeaderBuilder extends StatelessWidget {
  final List<ChatDetailsActions> actions;

  final double? width;

  final double? iconSize;

  final double? borderRadius;

  final BorderSide? borderSide;

  final EdgeInsetsDirectional? padding;

  final Color? buttonColor;

  final Color? iconColor;

  final OnTapIconButtonCallbackAction? onTap;

  const ActionsHeaderBuilder({
    super.key,
    required this.actions,
    this.width,
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
    return Padding(
      padding: const EdgeInsetsDirectional.all(16.0),
      child: Wrap(
        spacing: 16,
        children: actions.map((action) {
          return ChatDetailsActionsButton(
            title: action.getTitle(context),
            onTap: () => onTap!(action),
            iconData: action.getIconData(),
            iconSize: iconSize,
            width: width,
            borderRadius: borderRadius,
            borderSide: borderSide,
            padding: padding,
            buttonColor: buttonColor,
            iconColor: iconColor,
          );
        }).toList(),
      ),
    );
  }
}
