import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum SelectMode {
  normal,
  select,
}

enum PopupMenuAction {
  settings,
  invite,
  newGroup,
  setStatus,
  archive,
}

enum ActiveFilter {
  allChats,
  groups,
  messages,
  spaces,
}

enum ChatListSelectionActions {
  read,
  mute,
  pin,
  more;

  String getTitleForMobile(BuildContext context) {
    switch (this) {
      case ChatListSelectionActions.read:
        return L10n.of(context)!.contacts;
      case ChatListSelectionActions.mute:
        return L10n.of(context)!.mute;
      case ChatListSelectionActions.pin:
        return L10n.of(context)!.pin;
      case ChatListSelectionActions.more:
        return L10n.of(context)!.more;
    }
  }

  IconData getIcon(
    BuildContext context, {
    bool isMobile = true,
  }) {
    switch (this) {
      case ChatListSelectionActions.read:
        if (isMobile) {
          return Icons.mark_email_read;
        } else {
          return Icons.mark_chat_read;
        }
      case ChatListSelectionActions.mute:
        if (isMobile) {
          return Icons.notifications_off;
        } else {
          return Icons.volume_off;
        }

      case ChatListSelectionActions.pin:
        return Icons.push_pin;
      case ChatListSelectionActions.more:
        return Icons.more_vert;
    }
  }
}
