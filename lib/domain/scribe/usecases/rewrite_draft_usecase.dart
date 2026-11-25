import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_source.dart';

class RewriteDraftUseCase {
  const RewriteDraftUseCase({
    required ScribeSource source,
    required Future<DriveSession> Function() obtainSession,
    required Future<DriveSession> Function() renewSession,
    required String? Function() currentAccount,
  }) : _source = source,
       _obtainSession = obtainSession,
       _renewSession = renewSession,
       _currentAccount = currentAccount;

  final ScribeSource _source;

  final Future<DriveSession> Function() _obtainSession;

  final Future<DriveSession> Function() _renewSession;

  final String? Function() _currentAccount;

  Future<String> execute({
    required ScribeRoom room,
    required ScribePrompt prompt,
    required String draft,
  }) async {
    if (!room.offersScribe) throw const ScribeNotOffered();
    if (draft.trim().isEmpty) throw const ScribeEmptyDraft();
    final account = _currentAccount();
    if (account == null) throw const DriveSessionSuperseded();
    final session = await _obtainSession();
    _requireAccount(account);
    return _source.rewrite(
      session: session,
      renewSession: () => _renewFor(account),
      prompt: prompt,
      draft: draft,
    );
  }

  Future<DriveSession> _renewFor(String account) async {
    _requireAccount(account);
    final renewed = await _renewSession();
    _requireAccount(account);
    return renewed;
  }

  void _requireAccount(String account) {
    if (_currentAccount() != account) throw const DriveSessionSuperseded();
  }
}
