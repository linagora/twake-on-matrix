import 'package:twake_chat/domain/drive/entities/drive_intent.dart';
import 'package:twake_chat/domain/drive/entities/drive_picker_options.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/sources/drive_intent_source.dart';

/// Creates the intent whose page the picker loads, with the Drive token the
/// id token of [DriveSession] is exchanged for.
class CreateDriveIntentUseCase {
  const CreateDriveIntentUseCase(this._source);

  final DriveIntentSource _source;

  /// Throws as `DriveIntentSource.createIntent`.
  Future<DriveIntent> execute({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required DrivePickerOptions options,
  }) => _source.createIntent(
    session: session,
    renewSession: renewSession,
    options: options,
  );
}
