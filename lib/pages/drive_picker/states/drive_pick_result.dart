import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';

/// What a finished pick asks the caller to do.
sealed class DrivePickResult {
  const DrivePickResult();
}

/// Send [texts] as messages, in order: a link per line, no link split between
/// two messages.
final class DrivePickLinks extends DrivePickResult {
  const DrivePickLinks(this.texts);

  final List<String> texts;
}

/// Download [files], then send them as attachments. [skippedShortcuts] were
/// picked too but cannot be attached.
final class DrivePickAttach extends DrivePickResult {
  const DrivePickAttach(this.files, this.skippedShortcuts);

  final List<DrivePickedFile> files;
  final int skippedShortcuts;
}

/// Everything picked was a shortcut: there is nothing to attach.
final class DrivePickShortcutsOnly extends DrivePickResult {
  const DrivePickShortcutsOnly();
}

/// The user picked nothing.
final class DrivePickNothing extends DrivePickResult {
  const DrivePickNothing();
}

/// Drive failed, or nothing it gave back can be sent.
final class DrivePickFailed extends DrivePickResult {
  const DrivePickFailed(this.reason);

  final DrivePickFailure reason;
}

/// Why a pick ended in [DrivePickFailed]; named in the log, never the content.
///
/// The `picker*` and `intent*` values are what the picker package reported:
/// the page never said it was ready, it said it failed, or its intent did not
/// load.
enum DrivePickFailure {
  pickerFailed,
  pickerTimedOut,
  pickerPageFailed,
  pickerReportedError,
  pickerNoValidDocument,
  intentUnreachable,
  intentFailed,
  noLinkToSend,
  nothingToSend,
}
