import 'package:matrix/matrix.dart';

extension ClientStoredHomeserverExtension on Client {
  /// Checks the homeserver this client already holds, without losing it.
  ///
  /// [Client.checkHomeserver] sets [Client.homeserver] to `null` when the
  /// check fails. On a client that holds a session that would drop the stored
  /// homeserver, and a later fallback to a default one would send the session
  /// token to another server, which answers `M_UNKNOWN_TOKEN` and ends the
  /// session. The stored homeserver is restored when the check throws; the
  /// error is rethrown.
  ///
  /// Throws [StateError] when the client holds no homeserver.
  Future<
    (
      DiscoveryInformation?,
      GetVersionsResponse,
      List<LoginFlow>,
      GetAuthMetadataResponse?,
    )
  >
  checkStoredHomeserver() async {
    final stored = homeserver;
    if (stored == null) {
      throw StateError('The client holds no homeserver to check');
    }
    try {
      return await checkHomeserver(stored, checkWellKnown: false);
    } finally {
      homeserver ??= stored;
    }
  }
}
