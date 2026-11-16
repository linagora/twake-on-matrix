import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_stored_homeserver_extension.dart';

import '../../fake_client.dart';

/// Lets the SDK clear the session, which the plain mock database cannot.
class _ClearableDatabase extends MockDatabase {
  @override
  Future<void> clear() async {}
}

enum _Mode { healthy, unreachable, rejectsToken }

/// Delegates to [FakeMatrixApi] while healthy, otherwise fails like the
/// homeserver of the user would.
class _ModalClient extends http.BaseClient {
  _ModalClient(this._mode, this._onRequest);

  final _Mode Function() _mode;
  final void Function(Uri) _onRequest;
  final http.Client _healthy = FakeMatrixApi();

  /// While set, an unreachable request waits for it before failing.
  Completer<void>? holdUnreachable;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _onRequest(request.url);
    switch (_mode()) {
      case _Mode.healthy:
        return _healthy.send(request);
      case _Mode.unreachable:
        await holdUnreachable?.future;
        throw const SocketException('connection refused');
      case _Mode.rejectsToken:
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              '{"errcode":"M_UNKNOWN_TOKEN","error":"Unknown token"}',
            ),
          ),
          401,
          headers: {'content-type': 'application/json'},
        );
    }
  }
}

void main() {
  group('ClientStoredHomeserverExtension::checkStoredHomeserver', () {
    late Client client;
    late _Mode mode;
    late List<Uri> requested;

    late _ModalClient server;

    http.Client serverThat() =>
        server = _ModalClient(() => mode, (uri) => requested.add(uri));

    setUp(() async {
      mode = _Mode.healthy;
      requested = [];
      client = await getClient(
        httpClient: serverThat(),
        database: _ClearableDatabase(),
      );
      requested.clear();
    });

    tearDown(() async {
      await client.dispose(closeDatabase: false);
    });

    test('keeps the stored homeserver and the session when the homeserver '
        'is unreachable', () async {
      final stored = client.homeserver;
      mode = _Mode.unreachable;

      await expectLater(client.checkStoredHomeserver(), throwsA(anything));

      expect(client.homeserver, stored);
      expect(client.isLogged(), isTrue);
      expect(requested, isNotEmpty);
      expect(requested.every((uri) => uri.host == stored!.host), isTrue);
    });

    test('does not give the homeserver back to a client cleared while the '
        'check is in flight', () async {
      mode = _Mode.unreachable;
      server.holdUnreachable = Completer<void>();

      final check = expectLater(
        client.checkStoredHomeserver(),
        throwsA(anything),
      );
      await Future<void>.delayed(Duration.zero);
      await client.clear();
      server.holdUnreachable!.complete();
      await check;

      expect(client.isLogged(), isFalse);
      expect(client.homeserver, isNull);
    });

    test('does not give the old homeserver back to a session that replaced '
        'the one that started the check', () async {
      mode = _Mode.unreachable;
      server.holdUnreachable = Completer<void>();

      final check = expectLater(
        client.checkStoredHomeserver(),
        throwsA(anything),
      );
      await Future<void>.delayed(Duration.zero);
      // The user logs out and in again on the same client instance while the
      // check of the old homeserver is still in flight.
      client.accessToken = 'token-of-the-new-session';
      server.holdUnreachable!.complete();
      await check;

      expect(client.isLogged(), isTrue);
      expect(client.homeserver, isNull);
    });

    test(
      'the SDK check alone drops the homeserver (why the guard exists)',
      () async {
        mode = _Mode.unreachable;

        await expectLater(
          client.checkHomeserver(client.homeserver!, checkWellKnown: false),
          throwsA(anything),
        );

        expect(client.homeserver, isNull);
      },
    );

    test('throws a StateError when the client holds no homeserver', () async {
      client.homeserver = null;

      await expectLater(client.checkStoredHomeserver(), throwsStateError);
    });

    test('checks a healthy stored homeserver and keeps it', () async {
      final stored = client.homeserver;

      final (_, versions, _, _) = await client.checkStoredHomeserver();

      expect(versions.versions, isNotEmpty);
      expect(client.homeserver, stored);
      expect(requested, isNotEmpty);
    });

    test('a token rejected by the user\'s own homeserver still ends the '
        'session', () async {
      expect(client.isLogged(), isTrue);
      mode = _Mode.rejectsToken;

      await client.oneShotSync().catchError((_) {});

      expect(client.isLogged(), isFalse);
    });

    test(
      'an unreachable homeserver during sync does not end the session',
      () async {
        mode = _Mode.unreachable;

        await client.oneShotSync().catchError((_) {});

        expect(client.isLogged(), isTrue);
        expect(client.homeserver, isNotNull);
      },
    );
  });

  group('ClientStoredHomeserverExtension::homeserver refresh decisions', () {
    const defaultServer = 'https://default.example';
    late Client logged;
    late Client unlogged;

    setUp(() async {
      logged = await getClient(database: _ClearableDatabase());
      unlogged = Client('unlogged', database: _ClearableDatabase());
    });

    tearDown(() async {
      await logged.dispose(closeDatabase: false);
      await unlogged.dispose(closeDatabase: false);
    });

    test('a client with a session never receives the default homeserver', () {
      logged.homeserver = null;

      logged.applyDefaultHomeserverWithoutSession(defaultServer);

      expect(logged.homeserver, isNull);
    });

    test('a malformed default is not parsed for a client with a session', () {
      expect(
        () => logged.applyDefaultHomeserverWithoutSession('http://[malformed'),
        returnsNormally,
      );
      expect(logged.homeserver, isNotNull);
    });

    test('a client without a session receives the default homeserver', () {
      unlogged.applyDefaultHomeserverWithoutSession(defaultServer);

      expect(unlogged.homeserver, Uri.parse(defaultServer));
    });

    test('a client without a session keeps the homeserver it holds', () {
      final held = Uri.parse('https://held.example');
      unlogged.homeserver = held;

      unlogged.applyDefaultHomeserverWithoutSession(defaultServer);

      expect(unlogged.homeserver, held);
    });

    void expectRefresh(
      Client client, {
      required bool hasSummary,
      required bool lastCheckFailed,
      required bool refreshes,
    }) {
      expect(
        client.needsHomeserverInformationRefresh(
          hasSummary: hasSummary,
          lastCheckFailed: lastCheckFailed,
        ),
        refreshes,
      );
    }

    test('reconnect refreshes when the summary is missing', () {
      expectRefresh(
        logged,
        hasSummary: false,
        lastCheckFailed: false,
        refreshes: true,
      );
    });

    test('reconnect refreshes when the last check failed', () {
      expectRefresh(
        logged,
        hasSummary: true,
        lastCheckFailed: true,
        refreshes: true,
      );
    });

    test('reconnect refreshes a client that has no homeserver', () {
      unlogged.homeserver = null;

      expectRefresh(
        unlogged,
        hasSummary: true,
        lastCheckFailed: false,
        refreshes: true,
      );
    });

    test('reconnect does nothing when everything is known and healthy', () {
      expectRefresh(
        logged,
        hasSummary: true,
        lastCheckFailed: false,
        refreshes: false,
      );
    });
  });

  group('HomeserverCheckLog', () {
    late Client healthy;
    late Client unreachable;
    late HomeserverCheckLog log;
    late DateTime now;

    setUp(() {
      healthy = Client('healthy', database: _ClearableDatabase());
      unreachable = Client('unreachable', database: _ClearableDatabase());
      now = DateTime(2026, 11, 13);
      log = HomeserverCheckLog(now: () => now);
    });

    void waitRetryInterval() =>
        now = now.add(HomeserverCheckLog.retryAfterSync);

    tearDown(() async {
      await healthy.dispose(closeDatabase: false);
      await unreachable.dispose(closeDatabase: false);
    });

    void checked(Client client, {required bool failed}) {
      final ticket = log.begin(client);
      log.end(client, ticket);
      log.record(client, ticket, failed: failed);
    }

    test('a healthy account does not hide the failure of another one', () {
      checked(unreachable, failed: true);
      checked(healthy, failed: false);

      expect(log.hasFailed(unreachable), isTrue);
      expect(log.hasFailed(healthy), isFalse);
    });

    test('a later successful check clears the failure', () {
      checked(unreachable, failed: true);
      checked(unreachable, failed: false);

      expect(log.hasFailed(unreachable), isFalse);
    });

    test('only the latest refresh of an account may report', () {
      final first = log.begin(unreachable);
      final second = log.begin(unreachable);

      expect(log.isLatest(unreachable, first), isFalse);
      expect(log.isLatest(unreachable, second), isTrue);
    });

    test('a refresh of another account does not supersede this one', () {
      final ticket = log.begin(healthy);
      log.begin(unreachable);

      expect(log.isLatest(healthy, ticket), isTrue);
    });

    test('an account that was never checked has not failed', () {
      expect(log.hasFailed(healthy), isFalse);
    });

    test('a finished sync refreshes an account whose last check failed', () {
      checked(unreachable, failed: true);
      waitRetryInterval();

      expect(
        log.needsRefreshAfterSync(unreachable, SyncStatus.finished),
        isTrue,
      );
    });

    test('a sync that has not finished never refreshes', () {
      checked(unreachable, failed: true);

      for (final status in SyncStatus.values) {
        if (status == SyncStatus.finished) continue;
        expect(
          log.needsRefreshAfterSync(unreachable, status),
          isFalse,
          reason: '$status',
        );
      }
    });

    test('a finished sync does not refresh a healthy account', () {
      checked(healthy, failed: false);

      expect(log.needsRefreshAfterSync(healthy, SyncStatus.finished), isFalse);
    });

    test('a finished sync waits for the refresh already in flight', () {
      checked(unreachable, failed: true);
      final ticket = log.begin(unreachable);

      expect(
        log.needsRefreshAfterSync(unreachable, SyncStatus.finished),
        isFalse,
      );

      log.end(unreachable, ticket);
      waitRetryInterval();

      expect(
        log.needsRefreshAfterSync(unreachable, SyncStatus.finished),
        isTrue,
      );
    });

    test('a finished sync waits the retry interval after the last refresh', () {
      checked(unreachable, failed: true);
      now = now.add(
        HomeserverCheckLog.retryAfterSync - const Duration(seconds: 1),
      );

      expect(
        log.needsRefreshAfterSync(unreachable, SyncStatus.finished),
        isFalse,
      );

      now = now.add(const Duration(seconds: 1));

      expect(
        log.needsRefreshAfterSync(unreachable, SyncStatus.finished),
        isTrue,
      );
    });

    test('reconnect waits for the refresh already in flight', () {
      final ticket = log.begin(unreachable);

      expect(
        log.needsRefreshOnConnect(unreachable, hasSummary: false),
        isFalse,
      );

      log.end(unreachable, ticket);

      expect(log.needsRefreshOnConnect(unreachable, hasSummary: false), isTrue);
    });

    test('reconnect refreshes right away after a failed check', () {
      unreachable.homeserver = Uri.parse('https://matrix.example.org');
      checked(unreachable, failed: true);

      expect(log.needsRefreshOnConnect(unreachable, hasSummary: true), isTrue);
    });

    test('reconnect does nothing for a healthy account with a summary', () {
      healthy.homeserver = Uri.parse('https://matrix.example.org');
      checked(healthy, failed: false);

      expect(log.needsRefreshOnConnect(healthy, hasSummary: true), isFalse);
    });

    test('the end of a superseded refresh leaves the newer one in flight', () {
      final first = log.begin(unreachable);
      log.begin(unreachable);

      log.end(unreachable, first);

      expect(log.isRefreshing(unreachable), isTrue);
    });

    test('a superseded refresh cannot record its result', () {
      final stale = log.begin(unreachable);
      log.begin(unreachable);

      log.record(unreachable, stale, failed: true);

      expect(log.hasFailed(unreachable), isFalse);
    });

    test('the latest refresh applies when the homeserver did not change', () {
      unreachable.homeserver = Uri.parse('https://matrix.example.org');
      final ticket = log.begin(unreachable);

      expect(log.resultApplies(unreachable, ticket), isTrue);
    });

    test('a refresh does not apply when the homeserver changed meanwhile', () {
      unreachable.homeserver = Uri.parse('https://old.example.org');
      final ticket = log.begin(unreachable);

      unreachable.homeserver = Uri.parse('https://new.example.org');

      expect(log.resultApplies(unreachable, ticket), isFalse);
      expect(log.isLatest(unreachable, ticket), isTrue);
    });

    test(
      'a trailing slash dropped by the check is not a homeserver change',
      () {
        unreachable.homeserver = Uri.parse('https://matrix.example.org/');
        final ticket = log.begin(unreachable);

        unreachable.homeserver = Uri.parse('https://matrix.example.org');

        expect(log.resultApplies(unreachable, ticket), isTrue);
      },
    );

    test('a superseded refresh does not apply', () {
      final stale = log.begin(unreachable);
      log.begin(unreachable);

      expect(log.resultApplies(unreachable, stale), isFalse);
    });

    test('a logged out account forgets its failure and its refresh', () {
      checked(unreachable, failed: true);
      final ticket = log.begin(unreachable);

      log.forget(unreachable);

      expect(log.hasFailed(unreachable), isFalse);
      expect(log.isRefreshing(unreachable), isFalse);
      expect(log.isLatest(unreachable, ticket), isFalse);
    });

    test('a refresh from before a logout stays stale after a new login', () {
      final beforeLogout = log.begin(unreachable);
      log.forget(unreachable);
      final afterLogin = log.begin(unreachable);

      expect(log.isLatest(unreachable, beforeLogout), isFalse);
      expect(log.isLatest(unreachable, afterLogin), isTrue);
    });

    test('every sequence of steps keeps the invariants of each account', () {
      for (final steps in _stepSequences(length: 3)) {
        _expectInvariants(steps, first: healthy, second: unreachable);
      }
    });
  });
}

/// The latest flags are joined so two snapshots compare by value.
typedef _Snapshot = ({bool failed, bool refreshing, String latest});

_Snapshot _snapshot(HomeserverCheckLog log, Client client, List<int> tickets) =>
    (
      failed: log.hasFailed(client),
      refreshing: log.isRefreshing(client),
      latest: [
        for (final ticket in tickets) log.isLatest(client, ticket),
      ].join(','),
    );

void _expectInvariants(
  List<_Step> steps, {
  required Client first,
  required Client second,
}) {
  // Every reading of the clock is one retry interval later, so the throttle
  // never hides a refresh and the invariants stay about tickets and flags.
  var clock = DateTime(2026, 11, 13);
  final log = HomeserverCheckLog(
    now: () => clock = clock.add(HomeserverCheckLog.retryAfterSync),
  );
  final tickets = {first: <int>[], second: <int>[]};
  final done = <String>[];
  for (final step in steps) {
    final own = step.on(first, second);
    final other = own == first ? second : first;
    final ownBefore = _snapshot(log, own, tickets[own]!);
    final otherBefore = _snapshot(log, other, tickets[other]!);
    final ticket = step.ticketIn(tickets[own]!);
    final stale = ticket != null && !log.isLatest(own, ticket);

    step.apply(log, tickets[own]!, own);
    done.add(step.name);
    final reason = done.join(', ');
    final ownAfter = _snapshot(log, own, tickets[own]!);

    expect(_snapshot(log, other, tickets[other]!), otherBefore, reason: reason);
    if (stale) expect(ownAfter, ownBefore, reason: reason);
    if (step.forgets) {
      expect(ownAfter.failed, isFalse, reason: reason);
      expect(ownAfter.refreshing, isFalse, reason: reason);
      expect(ownAfter.latest, isNot(contains('true')), reason: reason);
    }
    expect(
      'true'.allMatches(ownAfter.latest).length,
      lessThanOrEqualTo(1),
      reason: reason,
    );
    expect(
      log.needsRefreshAfterSync(own, SyncStatus.finished),
      ownAfter.failed && !ownAfter.refreshing,
      reason: reason,
    );
  }
}

/// One step of the [HomeserverCheckLog] life cycle, on one of two accounts.
class _Step {
  const _Step(
    this.name,
    this._onFirst,
    this._run, {
    this.ticket,
    this.forgets = false,
  });

  final String name;
  final bool _onFirst;
  final void Function(HomeserverCheckLog log, List<int> tickets, Client client)
  _run;

  /// Which ticket of the account the step uses, if any.
  final int? Function(List<int> tickets)? ticket;
  final bool forgets;

  Client on(Client first, Client second) => _onFirst ? first : second;

  int? ticketIn(List<int> tickets) => ticket?.call(tickets);

  void apply(HomeserverCheckLog log, List<int> tickets, Client client) =>
      _run(log, tickets, client);
}

int? _latest(List<int> tickets) => tickets.isEmpty ? null : tickets.last;

int? _oldest(List<int> tickets) => tickets.isEmpty ? null : tickets.first;

List<_Step> _stepsOn({required bool first}) {
  final account = first ? 'first' : 'second';
  _Step withTicket(
    String name,
    int? Function(List<int>) pick,
    void Function(HomeserverCheckLog log, Client client, int ticket) run,
  ) => _Step('$name $account', first, (log, tickets, client) {
    final ticket = pick(tickets);
    if (ticket != null) run(log, client, ticket);
  }, ticket: pick);

  return [
    _Step(
      'begin $account',
      first,
      (log, tickets, client) => tickets.add(log.begin(client)),
    ),
    withTicket('end latest', _latest, (log, c, t) => log.end(c, t)),
    withTicket('end oldest', _oldest, (log, c, t) => log.end(c, t)),
    withTicket(
      'fail latest',
      _latest,
      (log, c, t) => log.record(c, t, failed: true),
    ),
    withTicket(
      'pass oldest',
      _oldest,
      (log, c, t) => log.record(c, t, failed: false),
    ),
    _Step(
      'forget $account',
      first,
      (log, _, client) => log.forget(client),
      forgets: true,
    ),
  ];
}

Iterable<List<_Step>> _stepSequences({required int length}) sync* {
  final steps = [..._stepsOn(first: true), ..._stepsOn(first: false)];
  Iterable<List<_Step>> extend(List<_Step> prefix) sync* {
    if (prefix.length == length) {
      yield prefix;
      return;
    }
    for (final step in steps) {
      yield* extend([...prefix, step]);
    }
  }

  yield* extend([]);
}
