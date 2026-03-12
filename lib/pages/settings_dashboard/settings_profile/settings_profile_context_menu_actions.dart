import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum SettingsProfileContextMenuActions {
  edit,
  delete;

  String getTitle(BuildContext context) {
    final l10n = L10n.of(context)!;
    switch (this) {
      case .edit:
        return l10n.changeProfileAvatar;
      case .delete:
        return l10n.removeYourAvatar;
    }
  }

  IconData getIcon() {
    switch (this) {
      case .edit:
        return Icons.camera_alt_outlined;
      case .delete:
        return Icons.delete;
    }
  }
}
