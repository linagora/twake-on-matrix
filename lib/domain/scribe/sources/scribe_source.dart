import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';

/// The AI route of the user's workplace, as one role: apply a prompt to a
/// draft. The app never talks to a language model itself.
abstract interface class ScribeSource {
  /// Returns the text that replaces [draft], trimmed and never empty.
  ///
  /// A token the workplace rejects as stale is renewed once through
  /// [renewSession] and the exchange is retried once; the request itself is
  /// sent once.
  ///
  /// Throws [DriveExchangeRejected] when the workplace refuses the token for
  /// good, [DriveChatAppMissing], [DriveRateLimited], [DriveTimedOut],
  /// [DriveOffline], and [ScribeRewriteFailed] for any other failure. A
  /// renewal that fails throws its [DriveException].
  Future<String> rewrite({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required ScribePrompt prompt,
    required String draft,
  });
}
