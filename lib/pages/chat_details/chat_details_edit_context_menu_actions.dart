import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

enum EditChatAvatarContextMenuActions {
  edit,
  delete;

  String getTitle(BuildContext context) {
    switch (this) {
      case EditChatAvatarContextMenuActions.edit:
        return L10n.of(context)!.changeChatAvatar;
      case EditChatAvatarContextMenuActions.delete:
        return L10n.of(context)!.removeYourAvatar;
    }
  }

  IconData getIcon() {
    switch (this) {
      case EditChatAvatarContextMenuActions.edit:
        return Icons.camera_alt_outlined;
      case EditChatAvatarContextMenuActions.delete:
        return Icons.delete;
    }
  }
}
