import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

class ScribeFailureMessage {
  const ScribeFailureMessage();

  String? of(L10n l10n, Exception error) => switch (error) {
    final ScribeException scribe => _ofScribe(l10n, scribe),
    final DriveException drive => _ofDrive(l10n, drive),
    _ => l10n.scribeRewriteFailed,
  };

  String? ofSetting(L10n l10n, Exception error) => switch (error) {
    ScribeRoomNotFound() => l10n.scribeSettingFailed,
    ScribeException() || DriveException() => of(l10n, error),
    _ => l10n.scribeSettingFailed,
  };

  String? _ofScribe(L10n l10n, ScribeException error) => switch (error) {
    ScribeNotOffered() => l10n.scribeNotOffered,
    ScribeEmptyDraft() => null,
    ScribeRewriteFailed() || ScribeRoomNotFound() => l10n.scribeRewriteFailed,
    ScribeSwitchFailed() => l10n.scribeSettingFailed,
  };

  String? _ofDrive(L10n l10n, DriveException error) => switch (error) {
    DriveSignInCancelled() || DriveSessionSuperseded() => null,
    DriveSignInFailed() ||
    DriveWorkplaceUnknown() ||
    DriveExchangeRejected() => l10n.scribeSignInFailed,
    DriveChatAppMissing() => l10n.driveChatAppMissing,
    DriveRateLimited() => l10n.scribeRateLimited,
    DriveTimedOut() => l10n.scribeTimedOut,
    DriveOffline() => l10n.scribeOffline,
    DriveNotConfigured() || DriveIntentFailed() => l10n.scribeRewriteFailed,
  };
}
