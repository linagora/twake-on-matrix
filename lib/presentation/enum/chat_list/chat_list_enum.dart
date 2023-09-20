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

enum ChatListBottomNavigatorBar {
  read,
  mute,
  pin,
  more;

  String title(BuildContext context) {
    switch (this) {
      case ChatListBottomNavigatorBar.read:
        return L10n.of(context)!.contacts;
      case ChatListBottomNavigatorBar.mute:
        return L10n.of(context)!.mute;
      case ChatListBottomNavigatorBar.pin:
        return L10n.of(context)!.pin;
      case ChatListBottomNavigatorBar.more:
        return L10n.of(context)!.more;
    }
  }

  IconData icon(BuildContext context) {
    switch (this) {
      case ChatListBottomNavigatorBar.read:
        return Icons.mark_email_read;
      case ChatListBottomNavigatorBar.mute:
        return Icons.notifications_off;
      case ChatListBottomNavigatorBar.pin:
        return Icons.push_pin;
      case ChatListBottomNavigatorBar.more:
        return Icons.more_vert;
    }
  }
}
