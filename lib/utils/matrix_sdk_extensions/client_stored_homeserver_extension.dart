import 'package:matrix/matrix.dart';

extension ClientStoredHomeserverExtension on Client {
  /// Checks the homeserver this client already holds, without losing it.
  ///
  /// [Client.checkHomeserver] sets [Client.homeserver] to `null` when the
  /// check fails. On a client that holds a session that would drop the stored
  /// homeserver, and a later fallback to a default one would send the session
  /// token to another server, which answers `M_UNKNOWN_TOKEN` and ends the
  /// session (an unknown token without `soft_logout` ends it, see
  /// https://spec.matrix.org/v1.16/client-server-api/#soft-logout). The stored homeserver is restored when the check throws; the
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
      // clear() nulls the homeserver on purpose when the session ends while
      // the check is in flight; only a client that is still logged in gets
      // its stored homeserver back.
      if (isLogged()) {
        homeserver ??= stored;
      }
    }
  }

  /// Gives a client without a session the [defaultHomeserver].
  ///
  /// A client that holds a session keeps its own homeserver: the default one
  /// would receive its token and answer `M_UNKNOWN_TOKEN`.
  void applyDefaultHomeserverWithoutSession(Uri defaultHomeserver) {
    if (!isLogged()) {
      homeserver ??= defaultHomeserver;
    }
  }

  /// Whether the homeserver information should be fetched again when the
  /// network returns: the client has no homeserver yet, no summary was
  /// stored, or the last check failed.
  bool needsHomeserverInformationRefresh({
    required bool hasSummary,
    required bool lastCheckFailed,
  }) => homeserver == null || !hasSummary || lastCheckFailed;
}

/// Remembers, per account, whether the last homeserver check failed.
///
/// One flag for all accounts would let a healthy account hide the failure of
/// another one after an account switch.
class HomeserverCheckLog {
  final Set<String> _failedClients = {};

  void record(Client client, {required bool failed}) {
    if (failed) {
      _failedClients.add(client.clientName);
    } else {
      _failedClients.remove(client.clientName);
    }
  }

  bool hasFailed(Client client) => _failedClients.contains(client.clientName);
}
