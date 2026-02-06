import 'package:fluffychat/presentation/model/chat/chat_details/chat_details_group_action.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class ChatDetailsMessageAction implements ChatDetailsGroupAction {
  ChatDetailsMessageAction({required this.onMessage});

  final void Function() onMessage;

  @override
  String getTitle(BuildContext context) {
    return L10n.of(context)!.message;
  }

  @override
  IconData get icon => Icons.chat_bubble_outline;

  @override
  VoidCallback get onTap => onMessage;

  @override
  void Function(BuildContext context, TapDownDetails details)? get onTapDown =>
      null;
}
