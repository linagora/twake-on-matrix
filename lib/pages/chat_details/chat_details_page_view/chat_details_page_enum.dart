import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

enum ChatDetailsPage {
  members,
  media,
  files,
  links,
  downloads;

  String getTitle(BuildContext context) {
    switch (this) {
      case ChatDetailsPage.members:
        return L10n.of(context)!.members;
      case ChatDetailsPage.media:
        return L10n.of(context)!.media;
      case ChatDetailsPage.files:
        return L10n.of(context)!.files;
      case ChatDetailsPage.links:
        return L10n.of(context)!.links;
      case ChatDetailsPage.downloads:
        return L10n.of(context)!.downloads;
    }
  }
}
