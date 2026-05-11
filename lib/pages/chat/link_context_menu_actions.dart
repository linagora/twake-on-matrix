import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum LinkContextMenuActions {
  copy;

  String getTitle(BuildContext context) {
    switch (this) {
      case LinkContextMenuActions.copy:
        return L10n.of(context)!.copyLink;
    }
  }

  IconData getIconData() {
    switch (this) {
      case LinkContextMenuActions.copy:
        return Icons.content_copy_outlined;
    }
  }
}
