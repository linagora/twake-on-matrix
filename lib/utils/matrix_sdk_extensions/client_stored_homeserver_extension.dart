import 'package:matrix/matrix.dart';

extension ClientStoredHomeserverExtension on Client {
  /// Checks the homeserver this client already holds, without losing it.
  ///
  /// [Client.checkHomeserver] sets [Client.homeserver] to `null` when the
  /// check fails. On a client that holds a session that would drop the stored
  /// homeserver, and a later fallback to a default one would send the session
  /// token to another server, which answers `M_UNKNOWN_TOKEN` and ends the
  /// session (an unknown token without `soft_logout` ends it, see
  /// https://spec.matrix.org/v1.16/client-server-api/#soft-logout).
  /// The stored homeserver is restored when the check throws; the error is
  /// rethrown.
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
  HomeserverCheckLog({DateTime Function() now = DateTime.now}) : _now = now;

  /// The least time between two refreshes started by finished syncs. A check
  /// can keep failing while sync works (a proxy that breaks `/login` only),
  /// and a sync finishes every few seconds.
  static const retryAfterSync = Duration(minutes: 1);

  final DateTime Function() _now;
  final Set<String> _failedClients = {};
  final Map<String, int> _latestRefresh = {};
  final Set<String> _refreshing = {};
  final Map<String, Uri?> _homeserverAtBegin = {};
  final Map<String, DateTime> _startedAt = {};

  /// Unique across accounts and logouts, so a refresh started before a
  /// logout never matches the ticket of a refresh after the next login.
  int _lastTicket = 0;

  /// Starts a refresh of [client] and returns its ticket.
  int begin(Client client) {
    final ticket = ++_lastTicket;
    _latestRefresh[client.clientName] = ticket;
    _refreshing.add(client.clientName);
    _homeserverAtBegin[client.clientName] = client.homeserver
        ?.stripTrailingSlash();
    _startedAt[client.clientName] = _now();
    return ticket;
  }

  /// Ends the refresh of [client] that holds [ticket]. A superseded refresh
  /// leaves the newer one in flight.
  void end(Client client, int ticket) {
    if (isLatest(client, ticket)) _refreshing.remove(client.clientName);
  }

  /// Whether [ticket] still belongs to the latest refresh of [client].
  bool isLatest(Client client, int ticket) =>
      _latestRefresh[client.clientName] == ticket;

  /// Whether the result of the refresh that holds [ticket] may be applied:
  /// it is the latest refresh, and [client] still holds the homeserver it
  /// started with. The discovery and the check are read at different times;
  /// a homeserver changed in between would mix two servers in one summary.
  bool resultApplies(Client client, int ticket) =>
      isLatest(client, ticket) &&
      client.homeserver?.stripTrailingSlash() ==
          _homeserverAtBegin[client.clientName];

  bool isRefreshing(Client client) => _refreshing.contains(client.clientName);

  /// Records the result of the refresh that holds [ticket]. A superseded
  /// refresh records nothing: a newer one owns the result.
  void record(Client client, int ticket, {required bool failed}) {
    if (!isLatest(client, ticket)) return;
    if (failed) {
      _failedClients.add(client.clientName);
    } else {
      _failedClients.remove(client.clientName);
    }
  }

  bool hasFailed(Client client) => _failedClients.contains(client.clientName);

  /// Drops what is known about [client] when its session ends: a later
  /// login under the same client name starts clean.
  void forget(Client client) {
    _failedClients.remove(client.clientName);
    _latestRefresh.remove(client.clientName);
    _refreshing.remove(client.clientName);
    _homeserverAtBegin.remove(client.clientName);
    _startedAt.remove(client.clientName);
  }

  /// Whether a sync of [client] that ended with [status] should refresh its
  /// homeserver information: the homeserver answers again after a failed
  /// check, with no network change to trigger a reconnect. One refresh at a
  /// time: syncs that finish while it runs do not start another, and the
  /// next one waits [retryAfterSync] after the last refresh started.
  bool needsRefreshAfterSync(Client client, SyncStatus status) =>
      status == SyncStatus.finished &&
      hasFailed(client) &&
      !isRefreshing(client) &&
      !_startedWithin(client, retryAfterSync);

  /// Whether a reconnect should refresh the homeserver information of
  /// [client]: none is in flight (at boot the account switch already runs
  /// one), and [ClientStoredHomeserverExtension.needsHomeserverInformationRefresh]
  /// says so.
  bool needsRefreshOnConnect(Client client, {required bool hasSummary}) =>
      !isRefreshing(client) &&
      client.needsHomeserverInformationRefresh(
        hasSummary: hasSummary,
        lastCheckFailed: hasFailed(client),
      );

  bool _startedWithin(Client client, Duration interval) {
    final startedAt = _startedAt[client.clientName];
    return startedAt != null && _now().difference(startedAt) < interval;
  }
}
