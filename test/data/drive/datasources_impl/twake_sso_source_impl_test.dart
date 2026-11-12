import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/drive/datasources_impl/twake_sso_source_impl.dart';
import 'package:twake_chat/data/drive/sources/pkce_generator.dart';
import 'package:twake_chat/data/drive/sources/web_auth_launcher.dart';
import 'package:twake_chat/domain/drive/entities/drive_config.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';

import '../support/fake_http_adapter.dart';

const _sso = 'https://sso.example';
const _clientId = 'twake-chat-mobile';

String _segment(Object json) =>
    base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

String _jwt(Map<String, Object?> claims) =>
    '${_segment({'alg': 'RS512'})}.${_segment(claims)}.signature';

class _FakeLauncher implements WebAuthLauncher {
  _FakeLauncher(this._respond);

  final FutureOr<String> Function(Uri authorizeUrl) _respond;
  Uri? lastUrl;
  String? lastScheme;

  @override
  Future<String> authenticate({
    required String url,
    required String callbackScheme,
  }) async {
    lastUrl = Uri.parse(url);
    lastScheme = callbackScheme;
    return await _respond(lastUrl!);
  }
}

void main() {
  final now = DateTime.utc(2026, 11, 3, 12);
  final exp = now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
  const config = DriveConfig(ssoUrl: _sso, ssoClientId: _clientId);

  late _FakeLauncher launcher;
  late FakeHttpAdapter adapter;
  late Map<String, Object?> Function(Uri authorizeUrl) claimsFor;
  late ResponseBody Function(RequestOptions options) tokenAnswer;

  Map<String, Object?> goodClaims(Uri authorizeUrl) => {
    'iss': _sso,
    'aud': [_clientId],
    'exp': exp,
    'nonce': authorizeUrl.queryParameters['nonce'],
    'workplaceFqdn': 'alice.twake.example',
    'email': 'alice@example.com',
  };

  TwakeSsoSourceImpl source({
    DriveConfig sso = config,
    bool requireHttps = false,
    DioExceptionType? rejectWith,
  }) {
    final dio = Dio()..httpClientAdapter = adapter;
    if (rejectWith != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(requestOptions: options, type: rejectWith),
          ),
        ),
      );
    }
    return TwakeSsoSourceImpl(
      config: sso,
      requireHttps: requireHttps,
      dio: dio,
      pkce: PkceGenerator(_SeededRandom()),
      launcher: launcher,
      now: () => now,
    );
  }

  setUp(() {
    claimsFor = goodClaims;
    tokenAnswer = (options) =>
        jsonResponse({'id_token': _jwt(claimsFor(launcher.lastUrl!))});
    launcher = _FakeLauncher((url) {
      final state = url.queryParameters['state'];
      return 'twake.chat://login?code=the-code&state=$state';
    });
    adapter = FakeHttpAdapter((options) {
      if (options.path.endsWith('/.well-known/openid-configuration')) {
        return jsonResponse({
          'issuer': _sso,
          'authorization_endpoint': '$_sso/oauth2/authorize',
          'token_endpoint': '$_sso/oauth2/token',
        });
      }
      return tokenAnswer(options);
    });
  });

  group('TwakeSsoSourceImpl refresh token', () {
    test('signIn keeps the refresh token of the token endpoint', () async {
      tokenAnswer = (options) => jsonResponse({
        'id_token': _jwt(claimsFor(launcher.lastUrl!)),
        'refresh_token': 'the-refresh-token',
      });

      final token = await source().signIn();

      expect(token.refreshToken, 'the-refresh-token');
    });

    test('signIn works when the SSO sends no refresh token', () async {
      final token = await source().signIn();

      expect(token.refreshToken, isNull);
    });

    test('a refresh token never shows in the token text', () async {
      tokenAnswer = (options) => jsonResponse({
        'id_token': _jwt(claimsFor(launcher.lastUrl!)),
        'refresh_token': 'the-refresh-token',
      });

      final token = await source().signIn();

      expect(token.toString(), isNot(contains('the-refresh-token')));
    });

    group('refresh', () {
      Map<String, Object?> refreshedClaims() => {
        'iss': _sso,
        'aud': [_clientId],
        'exp': exp,
        'workplaceFqdn': 'alice.twake.example',
        'email': 'alice@example.com',
      };

      setUp(() {
        tokenAnswer = (options) => jsonResponse({
          'id_token': _jwt(refreshedClaims()),
          'access_token': 'sso-access-token',
        });
      });

      test('asks the token endpoint with the refresh grant, no secret and no '
          'browser', () async {
        await source().refresh('the-refresh-token');

        final request = adapter.requests.last;
        final form = request.data as Map<String, Object?>;
        expect(request.method, 'POST');
        expect(request.contentType, Headers.formUrlEncodedContentType);
        expect(form['grant_type'], 'refresh_token');
        expect(form['refresh_token'], 'the-refresh-token');
        expect(form['client_id'], _clientId);
        expect(form.containsKey('client_secret'), isFalse);
        expect(launcher.lastUrl, isNull);
      });

      test('returns the new id token and keeps the refresh token', () async {
        final token = await source().refresh('the-refresh-token');

        expect(token.value, isNotEmpty);
        expect(token.workplaceFqdn, 'alice.twake.example');
        expect(token.refreshToken, 'the-refresh-token');
      });

      test('keeps a rotated refresh token when the SSO sends one', () async {
        tokenAnswer = (options) => jsonResponse({
          'id_token': _jwt(refreshedClaims()),
          'refresh_token': 'rotated',
        });

        final token = await source().refresh('the-refresh-token');

        expect(token.refreshToken, 'rotated');
      });

      test(
        'a rejected refresh token fails as a token endpoint error',
        () async {
          tokenAnswer = (options) =>
              jsonResponse({'error': 'invalid_grant'}, 400);

          await expectLater(
            source().refresh('the-refresh-token'),
            _failsWith(DriveSignInFailure.tokenEndpoint),
          );
        },
      );

      final rejectedRefreshes = <String, Map<String, Object?>>{
        'of another audience': {
          'aud': ['someone-else'],
        },
        'that is already expired': {
          'exp': now.millisecondsSinceEpoch ~/ 1000 - 1,
        },
      };
      rejectedRefreshes.forEach((reason, override) {
        test('rejects a refreshed token $reason', () async {
          tokenAnswer = (options) => jsonResponse({
            'id_token': _jwt({...refreshedClaims(), ...override}),
          });

          await expectLater(
            source().refresh('the-refresh-token'),
            _failsWith(DriveSignInFailure.invalidIdToken),
          );
        });
      });

      test('maps the network errors of a refresh like a sign-in', () async {
        await expectLater(
          source(
            rejectWith: DioExceptionType.connectionError,
          ).refresh('the-refresh-token'),
          throwsA(isA<DriveOffline>()),
        );
      });
    });
  });

  group('TwakeSsoSourceImpl.signIn', () {
    test('returns the id token with the claims Drive needs', () async {
      final token = await source().signIn();

      expect(token.value, isNotEmpty);
      expect(
        token.expiresAt,
        DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true),
      );
      expect(token.workplaceFqdn, 'alice.twake.example');
    });

    test(
      'asks the browser for a code with PKCE S256 and the app redirect',
      () async {
        await source().signIn();

        final query = launcher.lastUrl!.queryParameters;
        expect(launcher.lastUrl!.origin, _sso);
        expect(query['response_type'], 'code');
        expect(query['client_id'], _clientId);
        expect(query['redirect_uri'], 'twake.chat://login');
        expect(query['scope'], 'openid profile email offline_access');
        expect(query['code_challenge_method'], 'S256');
        expect(query['prompt'], isNull);
        expect(launcher.lastScheme, 'twake.chat');
      },
    );

    test(
      'swaps the code with the verifier of the challenge, and no secret',
      () async {
        await source().signIn();

        final request = adapter.requests.last;
        final form = request.data as Map<String, Object?>;
        expect(request.method, 'POST');
        expect(request.contentType, Headers.formUrlEncodedContentType);
        expect(form['grant_type'], 'authorization_code');
        expect(form['code'], 'the-code');
        expect(form['client_id'], _clientId);
        expect(form['redirect_uri'], 'twake.chat://login');
        expect(form.containsKey('client_secret'), isFalse);
        expect(
          PkceGenerator(
            _SeededRandom(),
          ).challengeOf(form['code_verifier']! as String),
          launcher.lastUrl!.queryParameters['code_challenge'],
        );
        expect(request.headers.containsKey('Authorization'), isFalse);
      },
    );

    test('reads the discovery document once for several sign-ins', () async {
      final impl = source();

      await impl.signIn();
      await impl.signIn();

      final discoveries = adapter.requests.where(
        (r) => r.path.endsWith('/.well-known/openid-configuration'),
      );
      expect(discoveries, hasLength(1));
    });

    test('accepts a token that echoes our nonce', () async {
      claimsFor = (url) => {
        ...goodClaims(url),
        'nonce': url.queryParameters['nonce'],
      };

      final token = await source().signIn();

      expect(token.value, isNotEmpty);
    });

    final rejectedTokens = <String, Map<String, Object?> Function(Uri)>{
      'omits the requested nonce': (url) =>
          {...goodClaims(url)}..remove('nonce'),
      'has another nonce': (url) => {
        ...goodClaims(url),
        'nonce': 'someone-else',
      },
      'is issued for another client': (url) => {
        ...goodClaims(url),
        'aud': ['other-client'],
      },
      'has several audiences and no authorized party': (url) => {
        ...goodClaims(url),
        'aud': [_clientId, 'other-client'],
      },
      'has one audience and an authorized party that is another client':
          (url) => {...goodClaims(url), 'azp': 'other-client'},
      'has an authorized party that is another client': (url) => {
        ...goodClaims(url),
        'aud': [_clientId, 'other-client'],
        'azp': 'other-client',
      },
      'comes from another issuer': (url) => {
        ...goodClaims(url),
        'iss': 'https://evil.example',
      },
      'is already expired': (url) => {
        ...goodClaims(url),
        'exp':
            now.subtract(const Duration(seconds: 1)).millisecondsSinceEpoch ~/
            1000,
      },
    };
    rejectedTokens.forEach((reason, claims) {
      test('rejects a token that $reason', () async {
        claimsFor = claims;

        await expectLater(
          source().signIn(),
          _failsWith(DriveSignInFailure.invalidIdToken),
        );
      });
    });

    test('accepts multiple audiences when this client is authorized', () async {
      claimsFor = (url) => {
        ...goodClaims(url),
        'aud': [_clientId, 'other-client'],
        'azp': _clientId,
      };

      expect((await source().signIn()).value, isNotEmpty);
    });

    test('rejects an id token that is not a JWT', () async {
      tokenAnswer = (options) => jsonResponse({'id_token': 'garbage'});

      await expectLater(
        source().signIn(),
        _failsWith(DriveSignInFailure.invalidIdToken),
      );
    });

    test('fails when the token endpoint answers 400', () async {
      tokenAnswer = (options) => jsonResponse({'error': 'invalid_grant'}, 400);

      await expectLater(
        source().signIn(),
        _failsWith(DriveSignInFailure.tokenEndpoint),
      );
    });

    test('asks the token endpoint without following a redirect', () async {
      await source().signIn();

      final token = adapter.requests.firstWhere(
        (r) => r.path.endsWith('/oauth2/token'),
      );
      expect(token.followRedirects, isFalse);
    });

    test('reports a 429 from the token endpoint as rate limited', () async {
      tokenAnswer = (options) => jsonResponse({}, 429);

      await expectLater(source().signIn(), throwsA(isA<DriveRateLimited>()));
    });

    test('reports a discovery timeout separately', () async {
      await expectLater(
        source(rejectWith: DioExceptionType.connectionTimeout).signIn(),
        throwsA(isA<DriveTimedOut>()),
      );
    });

    test('reports an offline discovery separately', () async {
      await expectLater(
        source(rejectWith: DioExceptionType.connectionError).signIn(),
        throwsA(isA<DriveOffline>()),
      );
    });

    test('fails when the token endpoint sends no id token', () async {
      tokenAnswer = (options) => jsonResponse({'access_token': 'x'});

      await expectLater(
        source().signIn(),
        _failsWith(DriveSignInFailure.tokenEndpoint),
      );
    });

    test('fails when discovery is unreachable', () async {
      adapter = FakeHttpAdapter((options) => jsonResponse({}, 503));

      await expectLater(
        source().signIn(),
        _failsWith(DriveSignInFailure.discovery),
      );
    });

    test('does not follow a redirect of the discovery document', () async {
      adapter = FakeHttpAdapter(
        (options) => ResponseBody.fromString(
          '',
          302,
          headers: {
            'location': ['https://elsewhere.example/.well-known/x'],
          },
        ),
      );

      await expectLater(
        source().signIn(),
        _failsWith(DriveSignInFailure.discovery),
      );
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.followRedirects, isFalse);
    });

    test('fails when discovery lacks an endpoint', () async {
      adapter = FakeHttpAdapter((options) => jsonResponse({'issuer': _sso}));

      await expectLater(
        source().signIn(),
        _failsWith(DriveSignInFailure.discovery),
      );
    });

    test(
      'rejects discovery for another issuer before opening the browser',
      () async {
        adapter = FakeHttpAdapter(
          (options) => jsonResponse({
            'issuer': 'https://other.example',
            'authorization_endpoint': '$_sso/oauth2/authorize',
            'token_endpoint': '$_sso/oauth2/token',
          }),
        );

        await expectLater(
          source().signIn(),
          _failsWith(DriveSignInFailure.discovery),
        );
        expect(launcher.lastUrl, isNull);
      },
    );

    test('accepts an issuer that ends with a slash', () async {
      adapter = FakeHttpAdapter((options) {
        if (options.path.endsWith('/.well-known/openid-configuration')) {
          return jsonResponse({
            'issuer': '$_sso/',
            'authorization_endpoint': '$_sso/oauth2/authorize',
            'token_endpoint': '$_sso/oauth2/token',
          });
        }
        return tokenAnswer(options);
      });
      claimsFor = (url) => {...goodClaims(url), 'iss': '$_sso/'};

      final token = await source().signIn();

      expect(token.value, isNotEmpty);
    });

    test('is cancelled when the user closes the browser', () async {
      launcher = _FakeLauncher(
        (url) => throw PlatformException(code: 'CANCELED'),
      );

      await expectLater(
        source().signIn(),
        throwsA(isA<DriveSignInCancelled>()),
      );
    });

    test('a browser that never completes eventually times out the sign-in', () {
      fakeAsync((async) {
        launcher = _FakeLauncher((url) => Completer<String>().future);
        Object? failure;
        source().signIn().then<void>(
          (_) {},
          onError: (Object error) {
            failure = error;
          },
        );
        async.flushMicrotasks();

        async.elapse(TwakeSsoSourceImpl.browserTimeout);
        async.flushMicrotasks();

        expect(failure, isA<DriveTimedOut>());
      });
    });

    test('is cancelled when the user denies access', () async {
      launcher = _FakeLauncher(
        (url) => 'twake.chat://login?error=access_denied',
      );

      await expectLater(
        source().signIn(),
        throwsA(isA<DriveSignInCancelled>()),
      );
    });

    test('fails on another browser error', () async {
      launcher = _FakeLauncher(
        (url) => throw PlatformException(code: 'FAILED'),
      );

      await expectLater(
        source().signIn(),
        _failsWith(DriveSignInFailure.browser),
      );
    });

    test('fails on another error in the callback', () async {
      launcher = _FakeLauncher(
        (url) => 'twake.chat://login?error=server_error',
      );

      await expectLater(
        source().signIn(),
        _failsWith(DriveSignInFailure.callbackError),
      );
    });

    test('refuses a cleartext SSO url in a release build', () async {
      const cleartext = DriveConfig(
        ssoUrl: 'http://sso.example',
        ssoClientId: _clientId,
      );

      await expectLater(
        source(sso: cleartext, requireHttps: true).signIn(),
        throwsA(isA<DriveNotConfigured>()),
      );

      expect(adapter.requests, isEmpty);
    });

    test('refuses a cleartext endpoint named by the discovery', () async {
      adapter = FakeHttpAdapter(
        (options) => jsonResponse({
          'issuer': _sso,
          'authorization_endpoint': '$_sso/oauth2/authorize',
          'token_endpoint': 'http://sso.example/oauth2/token',
        }),
      );

      await expectLater(
        source(requireHttps: true).signIn(),
        _failsWith(DriveSignInFailure.discovery),
      );

      expect(launcher.lastUrl, isNull);
    });

    test(
      'fails, with no raw FormatException, on a malformed callback',
      () async {
        launcher = _FakeLauncher(
          (url) => 'twake.chat://redirect:bad/drive-sso?code=secret-code',
        );

        await expectLater(
          source().signIn(),
          _failsWith(DriveSignInFailure.callbackError),
        );
      },
    );

    test('fails when the state does not come back', () async {
      launcher = _FakeLauncher(
        (url) => 'twake.chat://login?code=the-code&state=forged',
      );

      await expectLater(
        source().signIn(),
        _failsWith(DriveSignInFailure.stateMismatch),
      );
    });

    test('fails when the callback has no code', () async {
      launcher = _FakeLauncher((url) {
        final state = url.queryParameters['state'];
        return 'twake.chat://login?state=$state';
      });

      await expectLater(
        source().signIn(),
        _failsWith(DriveSignInFailure.missingCode),
      );
    });

    test('does not call the token endpoint after a failed callback', () async {
      launcher = _FakeLauncher(
        (url) => 'twake.chat://login?code=c&state=forged',
      );

      await expectLater(source().signIn(), throwsA(isA<DriveSignInFailed>()));

      expect(
        adapter.requests.where((r) => r.path.endsWith('/oauth2/token')),
        isEmpty,
      );
    });
  });
}

Matcher _failsWith(DriveSignInFailure reason) =>
    throwsA(isA<DriveSignInFailed>().having((e) => e.reason, 'reason', reason));

/// Deterministic bytes, so two generators agree and the test can recompute the
/// challenge; the verifier itself is read back from the request.
class _SeededRandom implements Random {
  int _next = 7;

  @override
  int nextInt(int max) => _next = (_next * 31 + 11) % max;

  @override
  bool nextBool() => nextInt(2) == 1;

  @override
  double nextDouble() => nextInt(1 << 20) / (1 << 20);
}
