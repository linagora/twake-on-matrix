import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

enum SettingsProfileContextMenuActions {
  edit,
  delete;

  String getTitle(BuildContext context, {required bool hasAvatar}) {
    final l10n = L10n.of(context)!;
    return switch (this) {
      edit when hasAvatar => l10n.changeProfileAvatar,
      edit => l10n.setProfileAvatar,
      delete => l10n.removeYourAvatar,
    };
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
