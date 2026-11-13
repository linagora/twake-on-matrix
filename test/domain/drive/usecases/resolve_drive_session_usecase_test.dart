import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/drive/policy/drive_platform_url_policy.dart';
import 'package:twake_chat/domain/drive/policy/id_token_expiry_policy.dart';
import 'package:twake_chat/domain/drive/sources/twake_sso_source.dart';
import 'package:twake_chat/domain/drive/usecases/resolve_drive_session_usecase.dart';

class _FakeSsoSource implements TwakeSsoSource {
  _FakeSsoSource(this._signIn, {Future<DriveIdToken> Function(String)? refresh})
    : _refresh = refresh ?? ((_) async => throw StateError('no refresh'));

  final Future<DriveIdToken> Function() _signIn;
  final Future<DriveIdToken> Function(String refreshToken) _refresh;
  int signIns = 0;
  final refreshed = <String>[];

  @override
  Future<DriveIdToken> refresh(String refreshToken) {
    refreshed.add(refreshToken);
    return _refresh(refreshToken);
  }

  @override
  Future<DriveIdToken> signIn() {
    signIns++;
    return _signIn();
  }
}

void main() {
  final now = DateTime.utc(2026, 11, 3, 12);

  DriveIdToken token(String value, Duration left, {String? refreshToken}) =>
      DriveIdToken(
        value: value,
        expiresAt: now.add(left),
        workplaceFqdn: 'alice.twake.example',
        refreshToken: refreshToken,
      );

  ResolveDriveSessionUseCase useCase(_FakeSsoSource source) =>
      ResolveDriveSessionUseCase(
        ssoSource: source,
        urlPolicy: const DrivePlatformUrlPolicy(),
        expiryPolicy: const IdTokenExpiryPolicy(skew: Duration(seconds: 60)),
        now: () => now,
      );

  group('ResolveDriveSessionUseCase.execute', () {
    test('signs in when the caller holds no token', () async {
      final source = _FakeSsoSource(
        () async => token('new', const Duration(hours: 1)),
      );

      final session = await useCase(source).execute();

      expect(source.signIns, 1);
      expect(session.idToken.value, 'new');
      expect(session.platformUrl, Uri.parse('https://alice.twake.example'));
    });

    test('keeps a token that is still usable and does not sign in', () async {
      final source = _FakeSsoSource(
        () async => token('new', const Duration(hours: 1)),
      );

      final session = await useCase(
        source,
      ).execute(current: token('held', const Duration(minutes: 30)));

      expect(source.signIns, 0);
      expect(session.idToken.value, 'held');
    });

    test('signs in again when the held token is about to expire', () async {
      final source = _FakeSsoSource(
        () async => token('new', const Duration(hours: 1)),
      );

      final session = await useCase(
        source,
      ).execute(current: token('held', const Duration(seconds: 30)));

      expect(source.signIns, 1);
      expect(session.idToken.value, 'new');
    });

    test('lets a sign-in failure through, with no session', () async {
      final source = _FakeSsoSource(
        () async =>
            throw const DriveSignInFailed(DriveSignInFailure.tokenEndpoint),
      );

      await expectLater(
        useCase(source).execute(),
        throwsA(
          isA<DriveSignInFailed>().having(
            (e) => e.reason,
            'reason',
            DriveSignInFailure.tokenEndpoint,
          ),
        ),
      );
    });

    test('lets a cancelled sign-in through', () async {
      final source = _FakeSsoSource(
        () async => throw const DriveSignInCancelled(),
      );

      await expectLater(
        useCase(source).execute(),
        throwsA(isA<DriveSignInCancelled>()),
      );
    });

    test('fails with an unknown workplace when the claim is missing', () async {
      final source = _FakeSsoSource(
        () async => DriveIdToken(
          value: 'new',
          expiresAt: now.add(const Duration(hours: 1)),
        ),
      );

      await expectLater(
        useCase(source).execute(),
        throwsA(isA<DriveWorkplaceUnknown>()),
      );
    });
  });

  group('ResolveDriveSessionUseCase.execute with a refresh token', () {
    DriveIdToken expiredWithRefresh() =>
        token('old', const Duration(seconds: 10), refreshToken: 'r1');

    test('refreshes an expired token and does not open the browser', () async {
      final source = _FakeSsoSource(
        () async => token('browser', const Duration(hours: 1)),
        refresh: (r) async =>
            token('fresh', const Duration(hours: 1), refreshToken: r),
      );

      final session = await useCase(
        source,
      ).execute(current: expiredWithRefresh());

      expect(source.refreshed, ['r1']);
      expect(source.signIns, 0);
      expect(session.idToken.value, 'fresh');
      expect(session.idToken.refreshToken, 'r1');
    });

    test('signs in with the browser when the refreshed token is about to '
        'expire', () async {
      final source = _FakeSsoSource(
        () async => token('browser', const Duration(hours: 1)),
        refresh: (r) async =>
            token('short', const Duration(seconds: 30), refreshToken: r),
      );

      final session = await useCase(
        source,
      ).execute(current: expiredWithRefresh());

      expect(source.refreshed, ['r1']);
      expect(source.signIns, 1);
      expect(session.idToken.value, 'browser');
    });

    test('refuses a sign-in whose token is about to expire', () async {
      final source = _FakeSsoSource(
        () async => token('short', const Duration(seconds: 30)),
      );

      await expectLater(
        useCase(source).execute(),
        throwsA(
          isA<DriveSignInFailed>().having(
            (e) => e.reason,
            'reason',
            DriveSignInFailure.invalidIdToken,
          ),
        ),
      );
      expect(source.signIns, 1);
    });

    test('keeps a usable token and does not refresh', () async {
      final source = _FakeSsoSource(
        () async => token('browser', const Duration(hours: 1)),
      );

      final session = await useCase(source).execute(
        current: token('held', const Duration(hours: 1), refreshToken: 'r1'),
      );

      expect(source.refreshed, isEmpty);
      expect(source.signIns, 0);
      expect(session.idToken.value, 'held');
    });

    test('refreshes a usable token that Drive refused', () async {
      final source = _FakeSsoSource(
        () async => token('browser', const Duration(hours: 1)),
        refresh: (r) async =>
            token('fresh', const Duration(hours: 1), refreshToken: r),
      );

      final session = await useCase(source).execute(
        current: token('held', const Duration(hours: 1), refreshToken: 'r1'),
        refused: true,
      );

      expect(source.refreshed, ['r1']);
      expect(session.idToken.value, 'fresh');
    });

    test('signs in with the browser when the SSO refuses the refresh '
        'token', () async {
      final source = _FakeSsoSource(
        () async => token('browser', const Duration(hours: 1)),
        refresh: (_) async =>
            throw const DriveSignInFailed(DriveSignInFailure.tokenEndpoint),
      );

      final session = await useCase(
        source,
      ).execute(current: expiredWithRefresh());

      expect(source.refreshed, ['r1']);
      expect(source.signIns, 1);
      expect(session.idToken.value, 'browser');
    });

    test('lets a network failure of the refresh through, with no browser '
        'sign-in', () async {
      final source = _FakeSsoSource(
        () async => token('browser', const Duration(hours: 1)),
        refresh: (_) async => throw const DriveOffline(),
      );

      await expectLater(
        useCase(source).execute(current: expiredWithRefresh()),
        throwsA(isA<DriveOffline>()),
      );
      expect(source.signIns, 0);
    });

    test('signs in when the expired token has no refresh token', () async {
      final source = _FakeSsoSource(
        () async => token('browser', const Duration(hours: 1)),
      );

      final session = await useCase(
        source,
      ).execute(current: token('old', const Duration(seconds: 10)));

      expect(source.refreshed, isEmpty);
      expect(session.idToken.value, 'browser');
    });

    test('signs in when Drive refused a token that has no refresh '
        'token', () async {
      final source = _FakeSsoSource(
        () async => token('browser', const Duration(hours: 1)),
      );

      final session = await useCase(source).execute(
        current: token('held', const Duration(hours: 1)),
        refused: true,
      );

      expect(source.signIns, 1);
      expect(session.idToken.value, 'browser');
    });
  });
}
