import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

enum SelectMode {
  normal,
  select;

  bool get isSelectMode => this == SelectMode.select;
}

enum PopupMenuAction { settings, invite, newGroup, setStatus, archive }

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
        if (room.isMuted) {
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

  String getTitleContextMenuSelection(BuildContext context, Room room) {
    switch (this) {
      case ChatListSelectionActions.read:
        if (room.isUnreadOrInvited) {
          return L10n.of(context)!.markThisChatAsRead;
        } else {
          return L10n.of(context)!.markThisChatAsUnRead;
        }
      case ChatListSelectionActions.mute:
        if (room.isMuted) {
          return L10n.of(context)!.unmuteThisChat;
        } else {
          return L10n.of(context)!.muteThisChat;
        }
      case ChatListSelectionActions.pin:
        if (room.isFavourite) {
          return L10n.of(context)!.unpinThisChat;
        } else {
          return L10n.of(context)!.pinThisChat;
        }
      case ChatListSelectionActions.more:
        return L10n.of(context)!.more;
    }
  }
}
