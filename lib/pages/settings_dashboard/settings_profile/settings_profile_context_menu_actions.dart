import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

enum SettingsProfileContextMenuActions {
  edit,
  delete;

  String getTitle(BuildContext context) {
    switch (this) {
      case SettingsProfileContextMenuActions.edit:
        return L10n.of(context)!.changeProfileAvatar;
      case SettingsProfileContextMenuActions.delete:
        return L10n.of(context)!.removeYourAvatar;
    }
  }

  IconData getIcon() {
    switch (this) {
      case SettingsProfileContextMenuActions.edit:
        return Icons.camera_alt_outlined;
      case SettingsProfileContextMenuActions.delete:
        return Icons.delete;
    }
  }
}
