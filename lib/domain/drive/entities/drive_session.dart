import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';

part 'drive_session.freezed.dart';

/// What the rest of Drive needs to talk to the user's workplace: the SSO token
/// and the stack that takes it.
@freezed
abstract class DriveSession with _$DriveSession {
  const factory DriveSession({
    required DriveIdToken idToken,

    /// Base URL of the workplace stack (`<platformUrl>/auth/token_exchange`).
    required Uri platformUrl,
  }) = _DriveSession;
}
