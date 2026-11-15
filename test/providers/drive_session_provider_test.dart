import 'dart:async';

import 'package:matrix/matrix.dart' show Client;
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

import 'package:twake_chat/domain/drive/usecases/resolve_drive_session_usecase.provider.dart';
import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_config.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/drive/policy/drive_platform_url_policy.dart';
import 'package:twake_chat/domain/drive/policy/id_token_expiry_policy.dart';
import 'package:twake_chat/domain/drive/sources/twake_sso_source.dart';
import 'package:twake_chat/domain/drive/usecases/resolve_drive_session_usecase.dart';
import 'fake_active_user_id.dart';
import 'fake_sso_refresh_token_store.dart';
import 'package:twake_chat/providers/drive_session_provider.dart';
import 'package:twake_chat/providers/sso_token_vault_provider.dart';

final _now = DateTime.utc(2026, 11, 4);

enum _SessionPhase { absent, cached, obtaining, renewing }

enum _SessionOperation { obtain, renew, switchAccount }

/// A sign-in the test finishes by hand, to put two callers in flight at once.
class _GatedSsoSource implements TwakeSsoSource {
  final _pending = <Completer<DriveIdToken>>[];
  int get signIns => _pending.length;

  final refreshed = <String>[];
  DriveException? refreshFails;

  @override
  Future<DriveIdToken> refresh(String refreshToken) async {
    refreshed.add(refreshToken);
    final failure = refreshFails;
    if (failure != null) throw failure;
    return DriveIdToken(
      value: 'refreshed-$refreshToken',
      expiresAt: _now.add(const Duration(hours: 1)),
      workplaceFqdn: 'alice.twake.example',
      refreshToken: refreshToken,
    );
  }

  @override
  Future<DriveIdToken> signIn() {
    final completer = Completer<DriveIdToken>();
    _pending.add(completer);
    return completer.future;
  }

  /// The user the SSO names in a browser sign-in.
  String? subject;

  void complete(int index, String value, {String? refreshToken}) =>
      _pending[index].complete(
        DriveIdToken(
          value: value,
          subject: subject,
          expiresAt: _now.add(const Duration(hours: 1)),
          workplaceFqdn: 'alice.twake.example',
          refreshToken: refreshToken,
        ),
      );

  void fail(int index, DriveException error) =>
      _pending[index].completeError(error);
}

/// An account the app lists, on [homeserver].
class _Account extends Fake implements Client {
  _Account(this.userID, this.homeserver);

  @override
  final String userID;

  @override
  Uri? homeserver;
}

class _Accounts extends AccountClients {
  _Accounts(this.clients);

  final List<Client> clients;

  @override
  List<Client> build() => clients;
}

final _server = Uri.parse('https://matrix.example.org');

const _enabled = DriveConfig(
  ssoUrl: 'https://sso.example',
  ssoClientId: 'chat-mobile',
);

void main() {
  late _GatedSsoSource source;
  late FakeSsoRefreshTokenStore store;

  ProviderContainer container({
    DriveConfig config = _enabled,
    List<Client> accounts = const [],
  }) {
    final c = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        activeMatrixClientProvider.overrideWithValue(
          _Account('@alice:example.org', _server),
        ),
        accountClientsProvider.overrideWith(() => _Accounts(accounts)),
        followFakeActiveUserId(),
        useSsoRefreshTokenStore(store),
        driveConfigProvider.overrideWithValue(config),
        resolveDriveSessionUseCaseProvider.overrideWith(
          (ref) => ResolveDriveSessionUseCase(
            ssoSource: source,
            urlPolicy: const DrivePlatformUrlPolicy(),
            expiryPolicy: const IdTokenExpiryPolicy(
              skew: Duration(seconds: 60),
            ),
            now: () => _now,
          ),
        ),
      ],
    );
    // keepAlive notifier: hold it so the test controls its lifetime.
    c.listen(driveSessionProvider, (_, _) {});
    return c;
  }

  void switchAccount(ProviderContainer c, String userId) =>
      c.read(fakeActiveUserIdProvider.notifier).switchTo(userId);

  setUp(() {
    source = _GatedSsoSource();
    store = FakeSsoRefreshTokenStore();
  });

  group('DriveSessionNotifier with the refresh token of the secure store', () {
    const alice = '@alice:example.org';

    Future<DriveSession> obtainAfterSignIn(
      ProviderContainer c, {
      String? refreshToken,
    }) async {
      final pending = c.read(driveSessionProvider.notifier).obtain();
      await Future<void>.delayed(Duration.zero);
      source.complete(0, 'from-browser', refreshToken: refreshToken);
      return pending;
    }

    test(
      'refreshes the stored token after a restart and opens no browser',
      () async {
        store.tokens[alice] = 'kept';
        final c = container();

        final session = await c.read(driveSessionProvider.notifier).obtain();

        expect(session.idToken.value, 'refreshed-kept');
        expect(source.refreshed, ['kept']);
        expect(source.signIns, 0);
      },
    );

    test('refuses and forgets a sign-in of another user while another '
        'account of the server could be that user', () async {
      store.tokens[alice] = 'of-alice';
      source.refreshFails = const DriveSignInFailed(
        DriveSignInFailure.tokenEndpoint,
      );
      source.subject = 'bob';
      final c = container(accounts: [_Account('@bob:example.org', _server)]);

      await expectLater(
        obtainAfterSignIn(c),
        throwsA(
          isA<DriveSignInFailed>().having(
            (e) => e.reason,
            'reason',
            DriveSignInFailure.otherAccount,
          ),
        ),
      );
      expect(c.read(driveSessionProvider), isNull);
      expect(store.tokens[alice], isNull);
    });

    test('keeps a sign-in that names the account by its localpart', () async {
      source.subject = 'alice';
      final c = container(accounts: [_Account('@bob:example.org', _server)]);

      final session = await obtainAfterSignIn(c);

      expect(session.idToken.subject, 'alice');
    });

    test('never offers a token of another SSO to this one', () async {
      store.tokens[alice] = 'of-another-sso';
      store.issuers[alice] = 'https://another-sso.example';
      final c = container();

      final session = await obtainAfterSignIn(c);

      expect(source.refreshed, isEmpty);
      expect(session.idToken.value, 'from-browser');
    });

    test(
      'signs in with the browser when the SSO refuses the stored token',
      () async {
        store.tokens[alice] = 'stale';
        source.refreshFails = const DriveSignInFailed(
          DriveSignInFailure.tokenEndpoint,
        );
        final c = container();

        final session = await obtainAfterSignIn(c);

        expect(source.refreshed, ['stale']);
        expect(session.idToken.value, 'from-browser');
      },
    );

    test(
      'keeps the refresh token of a new sign-in for the next start',
      () async {
        final c = container();

        await obtainAfterSignIn(c, refreshToken: 'from-sso');

        expect(store.tokens[alice], 'from-sso');
      },
    );

    test('a token refreshed again is not written again', () async {
      store.tokens[alice] = 'kept';
      final c = container();

      await c.read(driveSessionProvider.notifier).obtain();

      expect(store.tokens[alice], 'kept');
      expect(store.writes, 0);
    });

    test('a store that cannot be read signs in with the browser', () async {
      store.failing = true;
      final c = container();

      final session = await obtainAfterSignIn(c);

      expect(session.idToken.value, 'from-browser');
    });

    test('a store that cannot be written does not fail the session', () async {
      final c = container();
      store.failing = true;

      final session = await obtainAfterSignIn(c, refreshToken: 'from-sso');

      expect(session.idToken.value, 'from-browser');
    });

    test('the token of another account is not used', () async {
      store.tokens['@bob:example.org'] = 'bobs';
      final c = container();

      await obtainAfterSignIn(c);

      expect(source.refreshed, isEmpty);
    });

    test('the tokens of the login come before the stored one', () async {
      store.tokens[alice] = 'kept';
      final c = container();
      c
          .read(ssoTokenVaultProvider)
          .put(
            alice,
            DriveIdToken(
              value: 'from-login',
              expiresAt: _now.add(const Duration(hours: 1)),
              workplaceFqdn: 'alice.twake.example',
              refreshToken: 'fresh',
            ),
          );

      final session = await c.read(driveSessionProvider.notifier).obtain();

      expect(session.idToken.value, 'from-login');
      expect(source.refreshed, isEmpty);
    });

    test('a switch while the store is read drops the stale answer', () async {
      store.tokens[alice] = 'kept';
      store.readGate = Completer<void>();
      final c = container();

      final pending = c.read(driveSessionProvider.notifier).obtain();
      final dropped = expectLater(
        pending,
        throwsA(isA<DriveSessionSuperseded>()),
      );
      await Future<void>.delayed(Duration.zero);
      switchAccount(c, '@bob:example.org');
      await Future<void>.delayed(Duration.zero);
      store.readGate!.complete();

      await dropped;
      expect(source.refreshed, isEmpty);
    });
  });

  group('DriveSessionNotifier with the tokens of the login', () {
    DriveIdToken loginToken({
      String value = 'from-login',
      Duration left = const Duration(hours: 1),
      String? refreshToken = 'r1',
    }) => DriveIdToken(
      value: value,
      expiresAt: _now.add(left),
      workplaceFqdn: 'alice.twake.example',
      refreshToken: refreshToken,
    );

    test('uses the token the login stored and opens no browser', () async {
      final c = container();
      c.read(ssoTokenVaultProvider).put('@alice:example.org', loginToken());

      final session = await c.read(driveSessionProvider.notifier).obtain();

      expect(session.idToken.value, 'from-login');
      expect(source.signIns, 0);
    });

    test('refreshes an expired login token and opens no browser', () async {
      final c = container();
      c
          .read(ssoTokenVaultProvider)
          .put('@alice:example.org', loginToken(left: Duration.zero));

      final session = await c.read(driveSessionProvider.notifier).obtain();

      expect(session.idToken.value, 'refreshed-r1');
      expect(source.refreshed, ['r1']);
      expect(source.signIns, 0);
    });

    test('keeps the stored tokens when the first attempt fails', () async {
      final c = container();
      final vault = c.read(ssoTokenVaultProvider)
        ..put('@alice:example.org', loginToken(left: Duration.zero));
      source.refreshFails = const DriveOffline();

      await expectLater(
        c.read(driveSessionProvider.notifier).obtain(),
        throwsA(isA<DriveOffline>()),
      );

      expect(vault.of('@alice:example.org'), isNotNull);
    });

    test('ignores the tokens stored for another account', () async {
      final c = container();
      c.read(ssoTokenVaultProvider).put('@bob:example.org', loginToken());

      final pending = c.read(driveSessionProvider.notifier).obtain();
      await Future<void>.delayed(Duration.zero);
      source.complete(0, 'browser');

      expect((await pending).idToken.value, 'browser');
      expect(source.signIns, 1);
    });

    test('drops the stored tokens once the session holds them', () async {
      final c = container();
      final vault = c.read(ssoTokenVaultProvider)
        ..put('@alice:example.org', loginToken());

      await c.read(driveSessionProvider.notifier).obtain();

      expect(vault.of('@alice:example.org'), isNull);
    });

    test('renew refreshes the held token instead of opening the '
        'browser', () async {
      final c = container();
      c.read(ssoTokenVaultProvider).put('@alice:example.org', loginToken());
      final notifier = c.read(driveSessionProvider.notifier);
      await notifier.obtain();

      final renewed = await notifier.renew();

      expect(renewed.idToken.value, 'refreshed-r1');
      expect(source.signIns, 0);
    });

    test('the tokens of a login finishing before the account becomes '
        'active are still found', () async {
      final c = container();
      c.read(driveSessionProvider);
      c.read(fakeActiveUserIdProvider.notifier).switchTo('@carol:example.org');
      c.read(ssoTokenVaultProvider).put('@carol:example.org', loginToken());

      final session = await c.read(driveSessionProvider.notifier).obtain();

      expect(session.idToken.value, 'from-login');
    });
  });

  group('DriveSessionNotifier.obtain', () {
    test('two concurrent callers share one sign-in and one session', () async {
      final c = container();
      final notifier = c.read(driveSessionProvider.notifier);

      final first = notifier.obtain();
      final second = notifier.obtain();
      await Future<void>.delayed(Duration.zero);
      source.complete(0, 'token');
      final sessions = await Future.wait([first, second]);

      expect(source.signIns, 1);
      expect(sessions.first, same(sessions.last));
    });

    test('a later call reuses the token while it is usable', () async {
      final c = container();
      final notifier = c.read(driveSessionProvider.notifier);
      final first = notifier.obtain();
      await Future<void>.delayed(Duration.zero);
      source.complete(0, 'token');
      await first;

      final again = await notifier.obtain();

      expect(source.signIns, 1);
      expect(again.idToken.value, 'token');
      expect(c.read(driveSessionProvider)?.idToken.value, 'token');
    });

    test(
      'a failed sign-in leaves no session and the next call retries',
      () async {
        final c = container();
        final notifier = c.read(driveSessionProvider.notifier);
        final failing = notifier.obtain();
        await Future<void>.delayed(Duration.zero);
        source.fail(
          0,
          const DriveSignInFailed(DriveSignInFailure.tokenEndpoint),
        );
        await expectLater(failing, throwsA(isA<DriveSignInFailed>()));
        expect(c.read(driveSessionProvider), isNull);

        final retry = notifier.obtain();
        await Future<void>.delayed(Duration.zero);
        source.complete(1, 'second');

        expect((await retry).idToken.value, 'second');
        expect(source.signIns, 2);
      },
    );

    test('is not configured when Drive is off, and signs nothing in', () async {
      final c = container(
        config: const DriveConfig(ssoUrl: '', ssoClientId: ''),
      );

      await expectLater(
        c.read(driveSessionProvider.notifier).obtain(),
        throwsA(isA<DriveNotConfigured>()),
      );
      expect(source.signIns, 0);
    });

    test('drops the session of the previous account on a switch', () async {
      final c = container();
      final notifier = c.read(driveSessionProvider.notifier);
      final held = notifier.obtain();
      await Future<void>.delayed(Duration.zero);
      source.complete(0, 'alice');
      await held;
      expect(c.read(driveSessionProvider)?.idToken.value, 'alice');

      switchAccount(c, '@bob:example.org');
      await Future<void>.delayed(Duration.zero);

      expect(c.read(driveSessionProvider), isNull);
    });

    test('a sign-in that finishes after a switch is dropped', () async {
      final c = container();
      final notifier = c.read(driveSessionProvider.notifier);
      final inFlight = notifier.obtain();
      await Future<void>.delayed(Duration.zero);

      switchAccount(c, '@bob:example.org');
      await Future<void>.delayed(Duration.zero);
      source.complete(0, 'old-account');

      await expectLater(inFlight, throwsA(isA<DriveSessionSuperseded>()));
      expect(c.read(driveSessionProvider), isNull);
    });

    test('after a switch the next caller signs in, not reuses', () async {
      final c = container();
      final notifier = c.read(driveSessionProvider.notifier);
      final stale = notifier.obtain();
      await Future<void>.delayed(Duration.zero);
      switchAccount(c, '@bob:example.org');
      await Future<void>.delayed(Duration.zero);

      final fresh = notifier.obtain();
      await Future<void>.delayed(Duration.zero);
      final staleDropped = expectLater(
        stale,
        throwsA(isA<DriveSessionSuperseded>()),
      );
      source.complete(1, 'new-account');
      source.complete(0, 'old-account');

      expect((await fresh).idToken.value, 'new-account');
      await staleDropped;
      expect(source.signIns, 2);
    });

    test('renewal starts after a failed obtain', () async {
      final c = container();
      final notifier = c.read(driveSessionProvider.notifier);
      final obtaining = notifier.obtain();
      await Future<void>.delayed(Duration.zero);
      final renewal = notifier.renew();
      final oldFailure = expectLater(
        obtaining,
        throwsA(isA<DriveSignInFailed>()),
      );
      source.fail(0, const DriveSignInFailed(DriveSignInFailure.tokenEndpoint));
      await oldFailure;
      await Future<void>.delayed(Duration.zero);
      expect(source.signIns, 2);

      source.complete(1, 'renewed');
      expect((await renewal).idToken.value, 'renewed');
    });

    test('a queued renewal stops when the account changes', () async {
      final c = container();
      final notifier = c.read(driveSessionProvider.notifier);
      final obtaining = notifier.obtain();
      await Future<void>.delayed(Duration.zero);
      final renewal = notifier.renew();
      final staleObtain = expectLater(
        obtaining,
        throwsA(isA<DriveSessionSuperseded>()),
      );
      final staleRenew = expectLater(
        renewal,
        throwsA(isA<DriveSessionSuperseded>()),
      );
      switchAccount(c, '@bob:example.org');
      await Future<void>.delayed(Duration.zero);
      source.complete(0, 'old-account');

      await staleObtain;
      await staleRenew;
      expect(source.signIns, 1);
      expect(c.read(driveSessionProvider), isNull);
    });
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> cacheFirstSession(DriveSessionNotifier notifier) async {
    final first = notifier.obtain();
    await settle();
    source.complete(0, 'cached');
    await first;
  }

  /// Puts [notifier] in [phase]; returns the sign-in still going on, if any.
  Future<({Future<DriveSession>? pending})> enter(
    DriveSessionNotifier notifier,
    _SessionPhase phase,
  ) async {
    Future<DriveSession>? pending;
    switch (phase) {
      case _SessionPhase.absent:
        break;
      case _SessionPhase.cached:
        await cacheFirstSession(notifier);
      case _SessionPhase.obtaining:
        pending = notifier.obtain();
        await settle();
      case _SessionPhase.renewing:
        await cacheFirstSession(notifier);
        pending = notifier.renew();
        await settle();
    }
    return (pending: pending);
  }

  Future<void> expectSwitchSupersedes(
    ProviderContainer c,
    Future<DriveSession>? pending,
  ) async {
    final stale = pending == null
        ? null
        : expectLater(pending, throwsA(isA<DriveSessionSuperseded>()));
    switchAccount(c, '@bob:example.org');
    await settle();
    if (pending != null) {
      source.complete(source.signIns - 1, 'stale');
      await stale;
    }
    expect(c.read(driveSessionProvider), isNull);
  }

  Future<void> expectRenewWaitsForSignIn(
    Future<DriveSession> action,
    Future<DriveSession>? pending,
  ) async {
    // Renewal waits for the current sign-in, then starts a fresh one.
    expect(source.signIns, 1);
    source.complete(0, 'refused');
    await pending;
    await settle();
    expect(source.signIns, 2);
    source.complete(1, 'renewed');
    expect((await action).idToken.value, 'renewed');
  }

  Future<void> expectNewSignIn(
    ProviderContainer c,
    Future<DriveSession> action,
    Future<DriveSession>? pending,
  ) async {
    final lastIndex = source.signIns - 1;
    expect(lastIndex, greaterThanOrEqualTo(0));
    source.complete(lastIndex, 'result');
    final result = await action;
    if (pending != null) expect(await pending, same(result));
    expect(result.idToken.value, 'result');
    expect(c.read(driveSessionProvider), same(result));
  }

  /// [obtain] or [renew] while in [phase].
  Future<void> expectCall(
    ProviderContainer c,
    _SessionPhase phase,
    _SessionOperation operation,
    Future<DriveSession>? pending,
  ) async {
    final notifier = c.read(driveSessionProvider.notifier);
    final action = operation == _SessionOperation.obtain
        ? notifier.obtain()
        : notifier.renew();
    await settle();
    final cachedObtain =
        phase == _SessionPhase.cached && operation == _SessionOperation.obtain;
    final renewDuringSignIn =
        phase == _SessionPhase.obtaining &&
        operation == _SessionOperation.renew;
    if (cachedObtain) {
      expect((await action).idToken.value, 'cached');
      expect(source.signIns, 1);
    } else if (renewDuringSignIn) {
      await expectRenewWaitsForSignIn(action, pending);
    } else {
      await expectNewSignIn(c, action, pending);
      expect(source.signIns, switch (phase) {
        _SessionPhase.absent || _SessionPhase.obtaining => 1,
        _SessionPhase.cached || _SessionPhase.renewing => 2,
      });
    }
  }

  group('DriveSessionNotifier state and operation matrix', () {
    for (final phase in _SessionPhase.values) {
      for (final operation in _SessionOperation.values) {
        test('${phase.name} x ${operation.name}', () async {
          final c = container();
          final notifier = c.read(driveSessionProvider.notifier);
          final pending = (await enter(notifier, phase)).pending;

          if (operation == _SessionOperation.switchAccount) {
            await expectSwitchSupersedes(c, pending);
          } else {
            await expectCall(c, phase, operation, pending);
          }
        });
      }
    }
  });
}
