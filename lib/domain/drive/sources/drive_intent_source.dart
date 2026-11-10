import 'package:twake_chat/domain/drive/entities/drive_intent.dart';
import 'package:twake_chat/domain/drive/entities/drive_picker_options.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';

/// Drive's side of the picker, as one role: trade the SSO id token for a Drive
/// token and create the intent whose page the picker loads.
abstract interface class DriveIntentSource {
  /// A token Drive rejects as stale is renewed once through [renewSession] and
  /// the exchange is retried once; a second rejection is final.
  ///
  /// Throws [DriveExchangeRejected] when Drive refuses the token for good,
  /// and [DriveIntentFailed] for any other failure.
  Future<DriveIntent> createIntent({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required DrivePickerOptions options,
  });
}
