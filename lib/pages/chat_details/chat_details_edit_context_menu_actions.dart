import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum ChatDetailsEditContextMenuActions {
  edit,
  delete;

  String getTitle(BuildContext context) {
    switch (this) {
      case ChatDetailsEditContextMenuActions.edit:
        return L10n.of(context)!.changeChatAvatar;
      case ChatDetailsEditContextMenuActions.delete:
        return L10n.of(context)!.removeYourAvatar;
    }
  }

  IconData getIcon() {
    switch (this) {
      case ChatDetailsEditContextMenuActions.edit:
        return Icons.camera_alt_outlined;
      case ChatDetailsEditContextMenuActions.delete:
        return Icons.delete;
    }
  }
}
