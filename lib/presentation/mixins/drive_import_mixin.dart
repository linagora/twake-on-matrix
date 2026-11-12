import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/drive/entities/drive_download_outcome.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';
import 'package:twake_chat/domain/drive/entities/drive_picker_options.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/drive_picker/drive_picker_controller.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_pending_file.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_pick_result.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_picker_preparation.dart';
import 'package:twake_chat/pages/drive_picker/widgets/drive_picker_page.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_drive_picker/core.dart' show DrivePickOutcome;
import 'package:twake_drive_picker/ui.dart'
    show resolveDrivePickerLocalizations;

/// What the chat gives the picker to act on a pick. Closures made when the user
/// tapped, so a pick that ends late can only go where it started.
class DriveImportActions {
  const DriveImportActions({
    required this.sendLinks,
    required this.onLinksSent,
    required this.maxAttachmentBytes,
    required this.sendFiles,
    required this.onFailure,
    required this.whileSigningIn,
  });

  /// Sends the text of the links as one message; a long pick is several, each
  /// cut between links.
  final Future<void> Function(String text) sendLinks;

  /// Runs once the links are queued.
  final VoidCallback onLinksSent;

  /// The homeserver upload limit, or null when it is not known. Must not throw.
  final Future<int?> Function() maxAttachmentBytes;

  /// Queues the files for upload, each shown in the chat at once. Their bytes
  /// follow: a file's `ready` completes when it is saved, or fails.
  final Future<void> Function(List<DrivePendingFile> files) sendFiles;

  /// Logs a step that threw. [step] names it; the chat owns logging, so this
  /// layer holds no Matrix SDK import.
  final void Function(String step, Object error, StackTrace stackTrace)
  onFailure;

  /// Runs the sign-in behind the app's loading dialog and gives back what it
  /// returned, or null when the dialog could not be shown. The task does not
  /// throw.
  final Future<DrivePickerPreparation?> Function(
    Future<DrivePickerPreparation?> Function() task,
  )
  whileSigningIn;
}

/// Glue between the chat and the Drive picker.
mixin DriveImportMixin {
  /// Opens Drive, then sends what the user picked: links as one message, or
  /// files downloaded and sent as attachments. The composer and its draft are
  /// the chat's to clear, in [DriveImportActions].
  Future<void> addFromTwakeDrive(
    BuildContext context, {
    required WidgetRef ref,
    required DriveImportActions actions,
  }) async {
    // Read before any await: the chat may be gone when the pick ends.
    final l10n = L10n.of(context)!;
    final pickerL10n = resolveDrivePickerLocalizations(context);
    final controller = ref.read(drivePickerControllerProvider.notifier);
    final options = DrivePickerOptions(
      linkLabel: pickerL10n.addAsLink,
      attachLabel: pickerL10n.addAsAttachment,
      darkTheme: Theme.of(context).brightness == Brightness.dark,
    );

    final preparation = await _prepare(controller, options, actions);
    if (preparation == null) {
      _tell(context, l10n.driveCouldNotOpen);
      return;
    }
    if (preparation is DrivePickerUnavailable) {
      _tell(context, _messageOf(preparation.problem, l10n));
      return;
    }
    if (preparation is! DrivePickerReady) return;
    final ticket = preparation.ticket;
    if (!context.mounted) {
      controller.release(ticket);
      return;
    }

    try {
      final result = await _openPicker(
        context,
        preparation.request,
        controller,
        ticket,
      );
      if (!context.mounted) return;
      await _act(context, result, controller, ticket, actions, l10n);
    } on Exception catch (error, stackTrace) {
      // The caller does not await this flow, so nothing else would hear it.
      actions.onFailure('pick', error, stackTrace);
      _tell(context, l10n.driveCouldNotOpen);
    } finally {
      controller.release(ticket);
    }
  }

  /// Signs in and loads what the picker needs, behind the app's loading
  /// dialog: the sign-in can take a while, and the composer shows nothing
  /// meanwhile. Null when it threw, which the task logs itself so the dialog
  /// does not show its own error as well.
  Future<DrivePickerPreparation?> _prepare(
    DrivePickerController controller,
    DrivePickerOptions options,
    DriveImportActions actions,
  ) {
    return actions.whileSigningIn(() async {
      try {
        return await controller.prepare(
          options,
          maxAttachmentBytes: actions.maxAttachmentBytes,
        );
      } on Exception catch (error, stackTrace) {
        actions.onFailure('prepare', error, stackTrace);
        return null;
      }
    });
  }

  /// Opens the picker page and turns what it returns into a result. A page
  /// left by the back button returns null: nothing was picked.
  Future<DrivePickResult> _openPicker(
    BuildContext context,
    DrivePickerRequest request,
    DrivePickerController controller,
    int ticket,
  ) async {
    final outcome = await Navigator.of(context, rootNavigator: true)
        .push<DrivePickOutcome>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => DrivePickerPage(request: request),
          ),
        );
    return outcome == null
        ? const DrivePickNothing()
        : controller.resultOf(outcome, ticket: ticket);
  }

  void _tell(BuildContext context, String message) {
    if (context.mounted) TwakeSnackBar.show(context, message);
  }

  Future<void> _act(
    BuildContext context,
    DrivePickResult result,
    DrivePickerController controller,
    int ticket,
    DriveImportActions actions,
    L10n l10n,
  ) async {
    switch (result) {
      case DrivePickNothing():
        return;
      case DrivePickFailed(:final reason):
        actions.onFailure('pick:${reason.name}', reason, StackTrace.current);
        TwakeSnackBar.show(context, l10n.driveCouldNotOpen);
      case DrivePickShortcutsOnly():
        TwakeSnackBar.show(context, l10n.driveShortcutsNotSent);
      case DrivePickLinks(:final texts):
        await _sendLinks(context, texts, controller, ticket, actions, l10n);
      case DrivePickAttach(:final files, :final skippedShortcuts):
        await _attach(
          context,
          controller,
          ticket,
          actions,
          l10n,
          files: files,
          skippedShortcuts: skippedShortcuts,
        );
    }
  }

  Future<void> _sendLinks(
    BuildContext context,
    List<String> texts,
    DrivePickerController controller,
    int ticket,
    DriveImportActions actions,
    L10n l10n,
  ) async {
    if (!controller.isCurrentPick(ticket)) return;
    try {
      for (final text in texts) {
        // The account may change while a message is on its way.
        if (!controller.isCurrentPick(ticket)) return;
        await actions.sendLinks(text);
      }
      if (context.mounted && controller.isCurrentPick(ticket)) {
        actions.onLinksSent();
      }
    } on Exception catch (error, stackTrace) {
      actions.onFailure('sendLinks', error, stackTrace);
      if (context.mounted && controller.isCurrentPick(ticket)) {
        TwakeSnackBar.show(context, l10n.driveCouldNotOpen);
      }
    }
  }

  Future<void> _attach(
    BuildContext context,
    DrivePickerController controller,
    int ticket,
    DriveImportActions actions,
    L10n l10n, {
    required List<DrivePickedFile> files,
    required int skippedShortcuts,
  }) async {
    if (!controller.isCurrentPick(ticket)) return;
    final pending = [
      for (final file in files)
        DrivePendingFile(
          file,
          download: (source) async => controller.downloadAgain(
            source,
            maxBytes: await actions.maxAttachmentBytes(),
          ),
        ),
    ];
    // The chat shows every file at once and the bytes follow, so the user is
    // never held. Drive's links last about five minutes: the download starts
    // now, not when the upload queue gets to each file.
    try {
      await actions.sendFiles(pending);
    } on Exception catch (error, stackTrace) {
      actions.onFailure('sendFiles', error, stackTrace);
      for (final file in pending) {
        file.fail();
      }
      if (context.mounted) {
        TwakeSnackBar.show(context, l10n.driveDownloadFailed);
      }
      return;
    }
    if (skippedShortcuts > 0 && context.mounted) {
      TwakeSnackBar.show(context, l10n.driveShortcutsNotSent);
    }
    try {
      final outcomes = await controller.download(
        files,
        ticket: ticket,
        onOutcome: (index, outcome) => pending[index].resolve(outcome),
      );
      // The failed bubbles say nothing by themselves.
      if (outcomes.any((o) => o is DriveDownloadRejected) && context.mounted) {
        TwakeSnackBar.show(context, l10n.driveDownloadFailed);
      }
    } on Exception catch (error, stackTrace) {
      actions.onFailure('download', error, stackTrace);
    } finally {
      // A file the download did not answer for will not come.
      for (final file in pending) {
        file.fail();
      }
    }
  }

  String _messageOf(DrivePickerProblem problem, L10n l10n) => switch (problem) {
    DrivePickerProblem.signInFailed => l10n.driveSignInFailed,
    DrivePickerProblem.chatAppMissing => l10n.driveChatAppMissing,
    DrivePickerProblem.couldNotOpen => l10n.driveCouldNotOpen,
  };
}
