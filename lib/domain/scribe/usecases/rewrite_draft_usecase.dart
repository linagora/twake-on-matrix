import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_source.dart';

/// Rewrites the whole draft of a composer with one Scribe option. Nothing
/// leaves the device for a room that does not offer the Scribe, or for a blank
/// draft.
class RewriteDraftUseCase {
  const RewriteDraftUseCase({
    required ScribeSource source,
    required Future<DriveSession> Function() obtainSession,
    required Future<DriveSession> Function() renewSession,
  }) : _source = source,
       _obtainSession = obtainSession,
       _renewSession = renewSession;

  final ScribeSource _source;

  /// Signs the user in to the workplace when needed.
  final Future<DriveSession> Function() _obtainSession;

  /// For a token the workplace refused as stale.
  final Future<DriveSession> Function() _renewSession;

  /// Returns the text that replaces [draft]; never sends a message.
  ///
  /// Throws [ScribeNotOffered] when [room] does not offer the Scribe and
  /// [ScribeEmptyDraft] when [draft] is blank, both before signing in. Then
  /// the `DriveException`s of signing in, and the [ScribeException]s of
  /// `ScribeSource.rewrite`.
  Future<String> execute({
    required ScribeRoom room,
    required ScribePrompt prompt,
    required String draft,
  }) async {
    if (!room.offersScribe) throw const ScribeNotOffered();
    if (draft.trim().isEmpty) throw const ScribeEmptyDraft();
    final session = await _obtainSession();
    return _source.rewrite(
      session: session,
      renewSession: _renewSession,
      prompt: prompt,
      draft: draft,
    );
  }
}
