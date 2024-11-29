import 'package:fluffychat/pages/chat/chat_actions_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

enum PickerType {
  gallery,
  documents,
  location,
  contact;

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
        return Icons.photo_outlined;
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
      case PickerType.documents:
        return ChatActionsStyle.colorBackgroundGalleryBottom;
      case PickerType.location:
        return ChatActionsStyle.colorBackgroundLocationBottom;
      case PickerType.contact:
        return ChatActionsStyle.colorBackgroundContactBottom;
    }
  }

  Color? getTextColor(BuildContext context) {
    switch (this) {
      case PickerType.gallery:
        return LinagoraSysColors.material().primary;
      case PickerType.documents:
        return LinagoraSysColors.material().tertiary;
      case PickerType.location:
      case PickerType.contact:
        return LinagoraSysColors.material().onBackground;
    }
  }
}

enum ChatScrollState {
  scrolling,
  startScroll,
  endScroll;

  bool get isScrolling => this == ChatScrollState.scrolling;

  bool get isStartScroll => this == ChatScrollState.startScroll;

  bool get isEndScroll => this == ChatScrollState.endScroll;
}

enum ChatAppBarActions {
  info,
  report,
  saveToDownload,
  saveToGallery,
  leaveGroup;

  String getTitle(BuildContext context) {
    switch (this) {
      case ChatAppBarActions.info:
        return L10n.of(context)!.messageInfo;
      case ChatAppBarActions.report:
        return L10n.of(context)!.reportMessage;
      case ChatAppBarActions.saveToDownload:
        return L10n.of(context)!.saveToDownloads;
      case ChatAppBarActions.saveToGallery:
        return L10n.of(context)!.saveToGallery;
      case ChatAppBarActions.leaveGroup:
        return L10n.of(context)!.commandHint_leave;
    }
  }

  IconData getIcon() {
    switch (this) {
      case ChatAppBarActions.info:
        return Icons.info_outlined;
      case ChatAppBarActions.report:
        return Icons.shield_outlined;
      case ChatAppBarActions.saveToDownload:
        return Icons.download_outlined;
      case ChatAppBarActions.saveToGallery:
        return Icons.save_outlined;
      case ChatAppBarActions.leaveGroup:
        return Icons.logout_outlined;
    }
  }

  Color getColorIcon(BuildContext context) {
    switch (this) {
      case ChatAppBarActions.info:
      case ChatAppBarActions.saveToDownload:
      case ChatAppBarActions.saveToGallery:
        return Theme.of(context).colorScheme.onSurface;
      case ChatAppBarActions.report:
        return LinagoraSysColors.material().errorDark;
      case ChatAppBarActions.leaveGroup:
        return Theme.of(context).colorScheme.error;
    }
  }

  EdgeInsets getPaddingTitle() {
    return const EdgeInsets.only(left: 20);
  }
}
