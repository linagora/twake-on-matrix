import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:json_annotation/json_annotation.dart'
    show CheckedFromJsonException;
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/data/drive/models/oidc_discovery_model.dart';
import 'package:twake_chat/data/drive/models/oidc_token_response_model.dart';
import 'package:twake_chat/data/drive/sources/id_token_claims.dart';
import 'package:twake_chat/data/drive/sources/pkce_generator.dart';
import 'package:twake_chat/data/drive/sources/web_auth_launcher.dart';
import 'package:twake_chat/domain/drive/entities/drive_config.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/drive/sources/twake_sso_source.dart';

/// OIDC authorization code flow with PKCE against the Twake SSO, in the
/// system browser. A public client: no secret.
///
/// Logs say where a step failed, never a token, a code, a verifier or a
/// state.
class TwakeSsoSourceImpl implements TwakeSsoSource {
  TwakeSsoSourceImpl({
    required DriveConfig config,
    required Dio dio,
    required PkceGenerator pkce,
    required WebAuthLauncher launcher,
    required DateTime Function() now,
    required bool requireHttps,
  }) : _config = config,
       _dio = dio,
       _pkce = pkce,
       _launcher = launcher,
       _now = now,
       _requireHttps = requireHttps;

  /// Must match the redirect registered for the client at the SSO and the
  /// `twake.chat` callback activity in the Android manifest and iOS plist.
  static const redirectUri = 'twake.chat://login';
  static const callbackScheme = 'twake.chat';
  // The scope of the `twake-chat-mobile` client, as the mobile single login
  // contract gives it; its id token carries `workplaceFqdn` without asking.
  static const scope = 'openid profile email offline_access';
  static const browserTimeout = Duration(minutes: 5);

  final DriveConfig _config;
  final Dio _dio;
  final PkceGenerator _pkce;
  final WebAuthLauncher _launcher;
  final DateTime Function() _now;

  /// Release builds only talk https. The id token is not signature-checked
  /// here: the TLS connection to the token endpoint is what vouches for it.
  final bool _requireHttps;

  /// Not a secret and the same for the whole run.
  OidcDiscoveryModel? _discovery;

  @override
  Future<DriveIdToken> signIn() async {
    final discovery = await _discover();
    final pkce = _pkce.generate();
    final state = _pkce.randomToken();
    final nonce = _pkce.randomToken();
    final callback = await _authorize(discovery, pkce, state, nonce);
    final code = _codeOf(callback, state);
    final answer = await _exchangeCode(discovery, code, pkce.verifier);
    return _verified(discovery, answer, nonce: nonce);
  }

  @override
  Future<DriveIdToken> refresh(String refreshToken) async {
    final discovery = await _discover();
    final answer = await _postToken(discovery, {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': _config.ssoClientId,
    });
    return _verified(
      discovery,
      answer,
      // The SSO sends no new refresh token on a refresh: keep this one.
      fallbackRefreshToken: refreshToken,
    );
  }

  Future<OidcDiscoveryModel> _discover() async {
    final cached = _discovery;
    if (cached != null) return cached;
    if (!_schemeAllowed(_config.ssoUrl)) throw const DriveNotConfigured();
    try {
      final response = await _dio.get<Object?>(
        '${_withoutTrailingSlash(_config.ssoUrl)}'
        '/.well-known/openid-configuration',
        // The endpoints of the document are checked against the issuer: a
        // document from elsewhere, by a redirect, is not the issuer's.
        options: Options(followRedirects: false),
      );
      return _discovery = _checked(
        OidcDiscoveryModel.fromJson(_asMap(response.data)),
      );
    } on DioException catch (e) {
      throw _failed(DriveSignInFailure.discovery, e);
    } on CheckedFromJsonException {
      throw _failed(DriveSignInFailure.discovery);
    } on FormatException {
      throw _failed(DriveSignInFailure.discovery);
    }
  }

  OidcDiscoveryModel _checked(OidcDiscoveryModel discovery) {
    if (!_issuerMatches(discovery) || !_endpointsAllowed(discovery)) {
      throw _failed(DriveSignInFailure.discovery);
    }
    return discovery;
  }

  bool _issuerMatches(OidcDiscoveryModel discovery) =>
      _withoutTrailingSlash(discovery.issuer) ==
      _withoutTrailingSlash(_config.ssoUrl);

  bool _endpointsAllowed(OidcDiscoveryModel discovery) =>
      _schemeAllowed(discovery.authorizationEndpoint) &&
      _schemeAllowed(discovery.tokenEndpoint);

  String _withoutTrailingSlash(String url) =>
      url.replaceAll(RegExp(r'/+$'), '');

  Future<String> _authorize(
    OidcDiscoveryModel discovery,
    PkcePair pkce,
    String state,
    String nonce,
  ) async {
    final url = Uri.parse(discovery.authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': _config.ssoClientId,
        'redirect_uri': redirectUri,
        'scope': scope,
        'code_challenge': pkce.challenge,
        'code_challenge_method': 'S256',
        'state': state,
        'nonce': nonce,
      },
    );
    try {
      return await _launcher
          .authenticate(url: url.toString(), callbackScheme: callbackScheme)
          .timeout(browserTimeout);
    } on TimeoutException {
      // The user did not come back in time: told, not read as a cancel.
      throw const DriveTimedOut();
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') throw const DriveSignInCancelled();
      throw _failed(DriveSignInFailure.browser);
    }
  }

  String _codeOf(String callback, String expectedState) {
    final Map<String, String> params;
    try {
      params = Uri.parse(callback).queryParameters;
    } on FormatException {
      // Its message repeats the callback, which carries the code: not logged.
      throw _failed(DriveSignInFailure.callbackError);
    }
    final error = params['error'];
    if (error == 'access_denied') throw const DriveSignInCancelled();
    if (error != null) throw _failed(DriveSignInFailure.callbackError);
    if (params['state'] != expectedState) {
      throw _failed(DriveSignInFailure.stateMismatch);
    }
    final code = params['code'];
    if (code == null || code.isEmpty) {
      throw _failed(DriveSignInFailure.missingCode);
    }
    return code;
  }

  Future<OidcTokenResponseModel> _exchangeCode(
    OidcDiscoveryModel discovery,
    String code,
    String verifier,
  ) => _postToken(discovery, {
    'grant_type': 'authorization_code',
    'code': code,
    'code_verifier': verifier,
    'redirect_uri': redirectUri,
    'client_id': _config.ssoClientId,
  });

  Future<OidcTokenResponseModel> _postToken(
    OidcDiscoveryModel discovery,
    Map<String, String> form,
  ) async {
    try {
      final response = await _dio.post<Object?>(
        discovery.tokenEndpoint,
        data: form,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          // A token endpoint that redirects is not the one discovered, and the
          // form holds the code (or the refresh token).
          followRedirects: false,
        ),
      );
      return OidcTokenResponseModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _failed(DriveSignInFailure.tokenEndpoint, e);
    } on CheckedFromJsonException {
      throw _failed(DriveSignInFailure.tokenEndpoint);
    } on FormatException {
      throw _failed(DriveSignInFailure.tokenEndpoint);
    }
  }

  /// [nonce] is the one a sign-in sent; a refresh sends none, so it checks
  /// none.
  DriveIdToken _verified(
    OidcDiscoveryModel discovery,
    OidcTokenResponseModel answer, {
    String? nonce,
    String? fallbackRefreshToken,
  }) {
    final idToken = answer.idToken;
    final IdTokenClaims claims;
    try {
      claims = IdTokenClaims.parse(idToken);
    } on FormatException {
      throw _failed(DriveSignInFailure.invalidIdToken);
    }
    final valid =
        claims.issuer == discovery.issuer &&
        claims.audience.contains(_config.ssoClientId) &&
        (claims.audience.length == 1 ||
            claims.authorizedParty == _config.ssoClientId) &&
        (claims.authorizedParty == null ||
            claims.authorizedParty == _config.ssoClientId) &&
        claims.expiresAt.isAfter(_now()) &&
        // OIDC Core 3.1.3.7 item 11 requires a sent nonce to come back.
        (nonce == null || claims.nonce == nonce);
    if (!valid) throw _failed(DriveSignInFailure.invalidIdToken);
    return DriveIdToken(
      value: idToken,
      expiresAt: claims.expiresAt,
      workplaceFqdn: claims.workplaceFqdn,
      subject: claims.subject,
      email: claims.email,
      refreshToken: answer.refreshToken ?? fallbackRefreshToken,
    );
  }

  bool _schemeAllowed(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.isScheme('https') || (!_requireHttps && uri.isScheme('http'));
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('the answer is not a JSON object');
  }

  DriveException _failed(DriveSignInFailure reason, [DioException? cause]) {
    final status = cause?.response?.statusCode;
    final message =
        'TwakeSsoSourceImpl: ${reason.name}'
        '${cause == null ? '' : ' (${cause.type.name}, status $status)'}';
    // The network, the SSO refusing a token, an `error=` in the callback and a
    // browser that cannot open are expected outcomes, mapped to a typed
    // exception below; only an answer that breaks the contract is an anomaly.
    final expected =
        cause != null ||
        reason == DriveSignInFailure.callbackError ||
        reason == DriveSignInFailure.browser;
    if (expected) {
      Logs().w(message);
    } else {
      Logs().e(message);
    }
    if (status == 429) return const DriveRateLimited();
    if (cause != null) {
      switch (cause.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          return const DriveTimedOut();
        case DioExceptionType.connectionError:
          return const DriveOffline();
        case DioExceptionType.badCertificate:
        case DioExceptionType.badResponse:
        case DioExceptionType.cancel:
        case DioExceptionType.unknown:
          break;
      }
    }
    return DriveSignInFailed(reason);
  }
}
