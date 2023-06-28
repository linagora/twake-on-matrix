import 'package:fluffychat/pages/chat/chat_actions_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum ChatActions {
  gallery,
  documents,
  location,
  contact
}

extension ChatActionsExtension on ChatActions {
  String getTitle(BuildContext context) {
    switch(this) {
      case ChatActions.gallery:
        return L10n.of(context)!.gallery;
      case ChatActions.documents:
        return L10n.of(context)!.documents;
      case ChatActions.location:
        return L10n.of(context)!.location;
      case ChatActions.contact:
        return L10n.of(context)!.contact;
    }
  }

  IconData getIcon() {
    switch(this) {
      case ChatActions.gallery:
        return Icons.photo;
      case ChatActions.documents:
        return Icons.attach_file;
      case ChatActions.location:
        return Icons.my_location;
      case ChatActions.contact:
        return Icons.person;
    }
  }

  Color getIconColor() {
    switch(this) {
      case ChatActions.gallery:
        return ChatActionsStyle.colorGalleryIcon;
      case ChatActions.documents:
        return ChatActionsStyle.colorDocumentIcon;
      case ChatActions.location:
        return ChatActionsStyle.colorLocationIcon;
      case ChatActions.contact:
        return ChatActionsStyle.colorContactIcon;
    }
  }

  Color getBackgroundColor() {
    switch(this) {
      case ChatActions.gallery:
        return ChatActionsStyle.colorBackgroundGalleryBottom;
      case ChatActions.documents:
        return ChatActionsStyle.colorBackgroundDocumentBottom;
      case ChatActions.location:
        return ChatActionsStyle.colorBackgroundLocationBottom;
      case ChatActions.contact:
        return ChatActionsStyle.colorBackgroundContactBottom;
    }
  }
}