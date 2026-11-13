import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';

/// Whether the Twake SSO signed in the Matrix account that asked, as the web
/// app decides it: the SSO names the user by its `sub` or the part of its
/// e-mail before the @, which is the localpart of the Matrix id. A token that
/// names someone else still serves the only account of its homeserver: the
/// identity provider may name its users otherwise, and there is no one else
/// to mistake it for.
class DriveAccountPolicy {
  const DriveAccountPolicy();

  bool owns(
    DriveIdToken token, {
    required String localpart,
    required int otherAccountsOnServer,
  }) {
    // An SSO may keep the case the user typed; a Matrix localpart is lower.
    final names = [
      token.subject,
      token.email?.split('@').first,
    ].whereType<String>().map((name) => name.toLowerCase());
    return names.contains(localpart.toLowerCase()) ||
        otherAccountsOnServer == 0;
  }
}
