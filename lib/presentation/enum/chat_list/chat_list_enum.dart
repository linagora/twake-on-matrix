import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

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

  IconData getIconBottomNavigation() {
    switch (this) {
      case ChatListSelectionActions.read:
        return Icons.mark_email_read;
      case ChatListSelectionActions.mute:
        return Icons.notifications_off;
      case ChatListSelectionActions.pin:
        return Icons.push_pin;
      case ChatListSelectionActions.more:
        return Icons.more_vert;
    }
  }

  IconData getIconContextMenuSelection(Room room) {
    switch (this) {
      case ChatListSelectionActions.read:
        if (room.markedUnread) {
          return Icons.mark_chat_read;
        } else {
          return Icons.mark_chat_unread;
        }
      case ChatListSelectionActions.mute:
        if (room.pushRuleState == PushRuleState.notify) {
          return Icons.volume_off;
        } else {
          return Icons.volume_up;
        }

      case ChatListSelectionActions.pin:
        if (room.isFavourite) {
          return Icons.push_pin_outlined;
        } else {
          return Icons.push_pin;
        }
      case ChatListSelectionActions.more:
        return Icons.more_vert;
    }
  }

  String getTitleContextMenuSelection(
    BuildContext context,
    Room room,
  ) {
    switch (this) {
      case ChatListSelectionActions.read:
        if (room.markedUnread) {
          return L10n.of(context)!.markThisMessageAsRead;
        } else {
          return L10n.of(context)!.markThisMessageAsUnRead;
        }
      case ChatListSelectionActions.mute:
        if (room.pushRuleState == PushRuleState.notify) {
          return L10n.of(context)!.muteThisMessage;
        } else {
          return L10n.of(context)!.unmuteThisMessage;
        }
      case ChatListSelectionActions.pin:
        return L10n.of(context)!.pinThisMessage;
      case ChatListSelectionActions.more:
        return L10n.of(context)!.more;
    }
  }
}
