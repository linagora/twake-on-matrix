import 'package:fluffychat/pages/chat/chat_actions_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum PickerType { gallery, documents, location, contact }

extension PickerTypeExtension on PickerType {
  String getTitle(BuildContext context) {
    switch (this) {
      case PickerType.gallery:
        return L10n.of(context)!.gallery;
      case PickerType.documents:
        return L10n.of(context)!.documents;
      case PickerType.location:
        return L10n.of(context)!.location;
      case PickerType.contact:
        return L10n.of(context)!.contact;
    }
  }

  IconData getIcon() {
    switch (this) {
      case PickerType.gallery:
        return Icons.photo;
      case PickerType.documents:
        return Icons.attach_file;
      case PickerType.location:
        return Icons.my_location;
      case PickerType.contact:
        return Icons.person;
    }
  }

  Color getIconColor() {
    switch (this) {
      case PickerType.gallery:
        return ChatActionsStyle.colorGalleryIcon;
      case PickerType.documents:
        return ChatActionsStyle.colorDocumentIcon;
      case PickerType.location:
        return ChatActionsStyle.colorLocationIcon;
      case PickerType.contact:
        return ChatActionsStyle.colorContactIcon;
    }
  }

  Color getBackgroundColor() {
    switch (this) {
      case PickerType.gallery:
        return ChatActionsStyle.colorBackgroundGalleryBottom;
      case PickerType.documents:
        return ChatActionsStyle.colorBackgroundDocumentBottom;
      case PickerType.location:
        return ChatActionsStyle.colorBackgroundLocationBottom;
      case PickerType.contact:
        return ChatActionsStyle.colorBackgroundContactBottom;
    }
  }
}
