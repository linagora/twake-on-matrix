import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

enum SelectMode {
  normal,
  select;

  bool get isSelectMode => this == SelectMode.select;
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
  acceptedChats,
  groups,
  messages,
  spaces;

  bool Function(Room) getRoomFilterByActiveFilter() {
    switch (this) {
      case ActiveFilter.allChats:
        return (room) => !room.isSpace && !room.isStoryRoom;
      case ActiveFilter.groups:
        return (room) =>
            !room.isSpace && !room.isDirectChat && !room.isStoryRoom;
      case ActiveFilter.messages:
        return (room) =>
            !room.isSpace && room.isDirectChat && !room.isStoryRoom;
      case ActiveFilter.spaces:
        return (r) => r.isSpace;
      case ActiveFilter.acceptedChats:
        return (room) =>
            !room.isSpace && !room.isStoryRoom && !room.isInvitation;
    }
  }
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

  String getTitleContextMenuSelection(
    BuildContext context,
    Room room,
  ) {
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
