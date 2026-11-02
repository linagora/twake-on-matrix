import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/exception/spaces/folder_exception.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/extensions/folder_extension.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/context_menu/context_menu_action.dart';
import 'package:twake_chat/widgets/mixins/twake_context_menu_mixin.dart';

/// What the user reads when a folder cannot be saved.
String folderErrorText(FolderException error, L10n l10n) => switch (error) {
  FolderNameRequiredException() => l10n.createNameRequired,
  FolderNameTakenException() => l10n.folderTaken,
  FolderSaveFailedException() => l10n.folderSaveFailed,
};

/// Runs a folder action and tells when it failed.
Future<bool> runFolderAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  final l10n = L10n.of(context)!;
  try {
    await action();
    return true;
  } on FolderException catch (error) {
    if (context.mounted) {
      TwakeSnackBar.show(context, folderErrorText(error, l10n));
    }
    return false;
  }
}

/// Asks, then removes the folder.
Future<void> confirmAndRemoveFolder(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) async {
  final l10n = L10n.of(context)!;
  final confirmed = await showConfirmAlertDialog(
    context: context,
    useRootNavigator: false,
    title: l10n.folderDeleteTitle,
    message: l10n.folderDeleteText,
    okLabel: l10n.delete,
    cancelLabel: l10n.cancel,
  );
  if (confirmed != ConfirmResult.ok || !context.mounted) return;
  final isRemoved = await runFolderAction(
    context,
    () => ref.read(foldersControllerProvider.notifier).remove(folder),
  );
  if (isRemoved && context.mounted) {
    TwakeSnackBar.show(context, l10n.folderDeleted);
  }
}

class _FolderMenu with TwakeContextMenuMixin {}

/// The menu of a chip, opened at the pointer like the one of a room.
Future<void> showFolderMenu(
  BuildContext context,
  WidgetRef ref, {
  required Folder folder,
  required Offset position,
}) async {
  final l10n = L10n.of(context)!;
  final menu = _FolderMenu()..disableRightClick();
  final index = await menu.showTwakeContextMenu(
    offset: position,
    context: context,
    listActions: [
      ContextMenuAction(name: l10n.folderEdit, icon: Icons.edit_outlined),
      ContextMenuAction(name: l10n.folderDelete, icon: Icons.delete_outline),
    ],
  );
  menu.enableRightClick();
  if (!context.mounted) return;
  switch (index) {
    case 0:
      await folder.pushEdit(context);
    case 1:
      await confirmAndRemoveFolder(context, ref, folder);
  }
}
