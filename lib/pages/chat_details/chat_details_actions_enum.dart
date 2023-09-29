import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum ChatDetailsActions {
  addMembers,
  mute,
  search,
  unmute,
  more;

  String getTitle(BuildContext context) {
    switch (this) {
      case ChatDetailsActions.addMembers:
        return L10n.of(context)!.addMembers;
      case ChatDetailsActions.mute:
        return L10n.of(context)!.mute;
      case ChatDetailsActions.unmute:
        return L10n.of(context)!.unmute;
      case ChatDetailsActions.search:
        return L10n.of(context)!.search;
      case ChatDetailsActions.more:
        return L10n.of(context)!.more;
    }
  }

  IconData getIconData() {
    switch (this) {
      case ChatDetailsActions.addMembers:
        return Icons.person_add;
      case ChatDetailsActions.mute:
        return Icons.notifications_none;
      case ChatDetailsActions.search:
        return Icons.search;
      case ChatDetailsActions.more:
        return Icons.more_horiz;
      case ChatDetailsActions.unmute:
        return Icons.notifications_off;
    }
  }
}
