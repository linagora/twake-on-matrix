import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';

/// Builds the URL of the user's workplace stack from the `workplaceFqdn` claim
/// of the id token: `https://<workplaceFqdn>`.
class DrivePlatformUrlPolicy {
  const DrivePlatformUrlPolicy();

  static final _host = RegExp(r'^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$');

  /// Throws [DriveWorkplaceUnknown] when the token has no claim or the claim
  /// is not a bare host name (a port, a path or user info would send the
  /// token elsewhere than to the workplace).
  Uri resolve(DriveIdToken token) {
    final fqdn = token.workplaceFqdn?.toLowerCase() ?? '';
    if (!_host.hasMatch(fqdn)) throw const DriveWorkplaceUnknown();
    return Uri.https(fqdn);
  }
}
