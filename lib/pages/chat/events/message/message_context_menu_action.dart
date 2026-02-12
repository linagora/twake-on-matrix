import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

enum MessageContextMenuAction {
  reply,
  forward,
  copy,
  report,
  edit,
  delete,
  select,
  pin,
  saveToDownload,
  saveToGallery;

  void onTap(BuildContext context) {
    switch (this) {
      case MessageContextMenuAction.reply:
        Navigator.of(context).pop('reply');
        break;
      case MessageContextMenuAction.forward:
        Navigator.of(context).pop('forward');
        break;
      case MessageContextMenuAction.copy:
        Navigator.of(context).pop('copy');
        break;
      case MessageContextMenuAction.report:
        Navigator.of(context).pop('report');
        break;
      case MessageContextMenuAction.select:
        Navigator.of(context).pop('select');
        break;
      case MessageContextMenuAction.pin:
        Navigator.of(context).pop('pin');
        break;
      case MessageContextMenuAction.saveToDownload:
        Navigator.of(context).pop('saveToDownload');
        break;
      case MessageContextMenuAction.saveToGallery:
        Navigator.of(context).pop('saveToGallery');
        break;
      case MessageContextMenuAction.edit:
        Navigator.of(context).pop('edit');
        break;
      case MessageContextMenuAction.delete:
        Navigator.of(context).pop('delete');
        break;
    }
  }

  String getTitle(BuildContext context, Event event) {
    switch (this) {
      case MessageContextMenuAction.reply:
        return L10n.of(context)!.reply;
      case MessageContextMenuAction.forward:
        return L10n.of(context)!.forward;
      case MessageContextMenuAction.copy:
        return L10n.of(context)!.copy;
      case MessageContextMenuAction.report:
        return L10n.of(context)!.report;
      case MessageContextMenuAction.select:
        return L10n.of(context)!.select;
      case MessageContextMenuAction.pin:
        return event.isPinned ? L10n.of(context)!.unpin : L10n.of(context)!.pin;
      case MessageContextMenuAction.saveToDownload:
        return L10n.of(context)!.saveToDownloads;
      case MessageContextMenuAction.saveToGallery:
        return L10n.of(context)!.saveToGallery;
      case MessageContextMenuAction.edit:
        return L10n.of(context)!.edit;
      case MessageContextMenuAction.delete:
        return L10n.of(context)!.delete;
    }
  }

  Color? getIconColor(BuildContext context, Event event) {
    if (this == MessageContextMenuAction.delete) {
      return LinagoraSysColors.material().error;
    }
    return null;
  }

  IconData? getIcon(Event event) {
    switch (this) {
      case MessageContextMenuAction.reply:
        return null;
      case MessageContextMenuAction.forward:
        return Icons.shortcut;
      case MessageContextMenuAction.copy:
        return Icons.content_copy;
      case MessageContextMenuAction.report:
        return Icons.flag_outlined;
      case MessageContextMenuAction.select:
        return Icons.check_circle_outline_outlined;
      case MessageContextMenuAction.pin:
        return event.isPinned ? null : Icons.push_pin_outlined;
      case MessageContextMenuAction.saveToDownload:
        return Icons.download_outlined;
      case MessageContextMenuAction.saveToGallery:
        return Icons.save_outlined;
      case MessageContextMenuAction.edit:
        return Icons.edit_outlined;
      case MessageContextMenuAction.delete:
        return Icons.delete_outlined;
    }
  }

  String? imagePath(Event event) {
    switch (this) {
      case MessageContextMenuAction.pin:
        return event.isPinned ? ImagePaths.icUnpin : null;
      case MessageContextMenuAction.reply:
        return ImagePaths.icReply;
      case MessageContextMenuAction.forward:
      case MessageContextMenuAction.edit:
      case MessageContextMenuAction.copy:
      case MessageContextMenuAction.report:
      case MessageContextMenuAction.select:
      case MessageContextMenuAction.saveToDownload:
      case MessageContextMenuAction.saveToGallery:
      case MessageContextMenuAction.delete:
        return null;
    }
  }
}
