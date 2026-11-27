import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';

abstract interface class ScribeSource {
  Future<String> rewrite({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required ScribePrompt prompt,
    required String draft,
  });
}
