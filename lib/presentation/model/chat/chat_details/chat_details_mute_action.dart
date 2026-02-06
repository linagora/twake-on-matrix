import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/presentation/model/chat/chat_details/chat_details_group_action.dart';
import 'package:flutter/material.dart';

class ChatDetailsMuteAction implements ChatDetailsGroupAction {
  ChatDetailsMuteAction({required this.onMute, required this.isMute});

  final VoidCallback onMute;
  final bool isMute;

  @override
  String getTitle(BuildContext context) {
    return isMute ? L10n.of(context)!.unmute : L10n.of(context)!.mute;
  }

  @override
  IconData get icon =>
      isMute ? Icons.notifications_off_outlined : Icons.notifications_outlined;

  @override
  VoidCallback get onTap => onMute;

  @override
  void Function(BuildContext context, TapDownDetails details)? get onTapDown =>
      null;
}
