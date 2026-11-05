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
    final sessionToken = accessToken;
    try {
      return await checkHomeserver(stored, checkWellKnown: false);
    } finally {
      // clear() nulls the homeserver on purpose when the session ends while
      // the check is in flight; only the session that started the check gets
      // its stored homeserver back. A new login on the same client instance
      // has another token, and the old homeserver is not its homeserver.
      if (isLogged() && accessToken == sessionToken) {
        homeserver ??= stored;
      }
    }
  }

  /// Gives a client without a session the [defaultHomeserver].
  ///
  /// A client that holds a session keeps its own homeserver: the default one
  /// would receive its token and answer `M_UNKNOWN_TOKEN`. The default is
  /// parsed only when it is used, so a malformed value cannot block the
  /// refresh of an account that already has a homeserver.
  void applyDefaultHomeserverWithoutSession(String defaultHomeserver) {
    if (!isLogged()) {
      homeserver ??= Uri.parse(defaultHomeserver);
    }
  }

  /// The discovery information to use when the well-known request fails.
  ///
  /// A client that holds a session relies on its own cached well-known: the
  /// [other] information comes from the account or the login picker that wrote
  /// the shared summary last, and could describe another homeserver. Using it
  /// would point the ToM base URL of this account at that server.
  DiscoveryInformation? discoveryFallbackFor(DiscoveryInformation? other) =>
      isLogged() ? null : other;

  /// Whether the homeserver information should be fetched again when the
  /// network returns: the client has no homeserver yet, no summary was
  /// stored, or the last check failed.
  bool needsHomeserverInformationRefresh({
    required bool hasSummary,
    required bool lastCheckFailed,
  }) => homeserver == null || !hasSummary || lastCheckFailed;
}

/// Remembers, per account, whether the last homeserver check failed and which
/// refresh is the latest one.
///
/// One flag for all accounts would let a healthy account hide the failure of
/// another one after an account switch. Refreshes of the same account can
/// overlap (the network flaps): only the latest one may write its result.
class HomeserverCheckLog {
  final Set<String> _failedClients = {};
  final Map<String, int> _latestRefresh = {};

  /// Starts a refresh of [client] and returns its ticket.
  int begin(Client client) => _latestRefresh.update(
    client.clientName,
    (ticket) => ticket + 1,
    ifAbsent: () => 1,
  );

  /// Whether [ticket] still belongs to the latest refresh of [client].
  bool isLatest(Client client, int ticket) =>
      _latestRefresh[client.clientName] == ticket;

  void record(Client client, {required bool failed}) {
    if (failed) {
      _failedClients.add(client.clientName);
    } else {
      _failedClients.remove(client.clientName);
    }
  }

  bool hasFailed(Client client) => _failedClients.contains(client.clientName);
}
