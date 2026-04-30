import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart';

/// Drives the SSO OIDC flow (steps 1-7) over `dart:io` `HttpClient` and
/// returns a one-time login token that can be handed to
/// `/onAuthRedirect?loginToken=…` to complete authentication inside the app.
Future<String> fetchOidcLoginToken({
  required String username,
  required String password,
}) async {
  const endpoints = _SsoEndpoints.fromEnvironment();
  final credentials = _Credentials(username: username, password: password);

  final client = HttpClient()..autoUncompress = true;
  try {
    final redirect = await _fetchOidcRedirect(client, endpoints);
    final authorizeUri = _buildAuthorizeUri(endpoints, redirect.params);
    final form = await _fetchSsoAuthorizeForm(
      client: client,
      authorizeUri: authorizeUri,
      endpoints: endpoints,
    );
    final submitResult = await _submitSsoCredentials(
      client: client,
      authorizeUri: authorizeUri,
      form: form,
      credentials: credentials,
    );
    return _exchangeCodeForLoginToken(
      client: client,
      endpoints: endpoints,
      redirect: redirect,
      submitResult: submitResult,
    );
  } finally {
    client.close(force: true);
  }
}

/// Sends a Matrix message as the configured receiver account via the
/// Client-Server API. Used by tests that need the receiving side to emit a
/// message while the primary account is logged in from the UI.
Future<void> sendMessageAsReceiver({required String message}) async {
  const endpoints = _SsoEndpoints.fromEnvironment();
  const groupID = String.fromEnvironment('GroupID');
  const receiver = String.fromEnvironment('Receiver');
  const passOfReceiver = String.fromEnvironment('ReceiverPass');

  final loginToken = await fetchOidcLoginToken(
    username: receiver,
    password: passOfReceiver,
  );

  final client = HttpClient()..autoUncompress = true;
  try {
    final session = await _loginWithMLoginToken(
      client: client,
      endpoints: endpoints,
      loginToken: loginToken,
    );
    await _putMatrixMessage(
      client: client,
      session: session,
      groupID: groupID,
      message: message,
    );
  } finally {
    client.close(force: true);
  }
}

// ---------------------------------------------------------------------------
// Configuration value types — collapse the 3 SSO URLs (matrix / sso / chat)
// and the user credentials into single args so private helpers stay under
// CodeScene's primitive-obsession / arg-count thresholds.
// ---------------------------------------------------------------------------

class _SsoEndpoints {
  const _SsoEndpoints({
    required this.matrixURL,
    required this.ssoURL,
    required this.chatURL,
  });

  const _SsoEndpoints.fromEnvironment()
    : matrixURL = const String.fromEnvironment('MATRIX_URL'),
      ssoURL = const String.fromEnvironment('SSO_URL'),
      chatURL = const String.fromEnvironment('CHAT_URL');

  final String matrixURL;
  final String ssoURL;
  final String chatURL;
}

class _Credentials {
  const _Credentials({required this.username, required this.password});
  final String username;
  final String password;
}

/// Authenticated Matrix session — the access token plus the endpoints needed
/// to reach `${matrixURL}` for follow-up calls.
class _MatrixSession {
  const _MatrixSession({required this.endpoints, required this.accessToken});
  final _SsoEndpoints endpoints;
  final String accessToken;
}

// ---------------------------------------------------------------------------
// OIDC flow — private step helpers
// ---------------------------------------------------------------------------

/// Result of step 1: GET matrix `/sso/redirect` with `redirects=false` and
/// capture the Location's query-params + the `oidc_session` cookie.
class _OidcRedirect {
  const _OidcRedirect({required this.params, required this.oidcSession});
  final Map<String, String> params;
  final String? oidcSession;
}

Future<_OidcRedirect> _fetchOidcRedirect(
  HttpClient client,
  _SsoEndpoints endpoints,
) async {
  final redirectUri = Uri.https(
    endpoints.matrixURL,
    '/_matrix/client/r0/login/sso/redirect/oidc-twake',
    {
      'redirectUrl':
          'https://${endpoints.chatURL}/web/auth.html'
          '?homeserver=https://${endpoints.matrixURL}',
    },
  );

  final request = await client.getUrl(redirectUri);
  request.followRedirects = false;
  _setCommonBrowserHeaders(request, endpoints.matrixURL);
  final response = await request.close();

  final location = response.headers.value('location');
  if (location == null) {
    throw Exception('No redirect location found in first response');
  }
  return _OidcRedirect(
    params: Uri.parse(location).queryParameters,
    oidcSession: _extractCookie(response.headers['set-cookie'], 'oidc_session'),
  );
}

Uri _buildAuthorizeUri(_SsoEndpoints endpoints, Map<String, String> params) =>
    Uri.https(endpoints.ssoURL, '/oauth2/authorize', {
      'response_type': params['response_type'],
      'client_id': params['client_id'],
      'redirect_uri': params['redirect_uri'],
      'scope': params['scope'],
      'state': params['state'],
      'nonce': params['nonce'],
      'code_challenge_method': params['code_challenge_method'],
      'code_challenge': params['code_challenge'],
    });

/// Result of step 2: GET SSO `/authorize` and parse the hidden HTML form.
class _SsoAuthorizeForm {
  const _SsoAuthorizeForm({
    required this.token,
    required this.url,
    required this.skin,
    required this.lemonldappdata,
  });
  final String token;
  final String url;
  final String skin;
  final String? lemonldappdata;
}

Future<_SsoAuthorizeForm> _fetchSsoAuthorizeForm({
  required HttpClient client,
  required Uri authorizeUri,
  required _SsoEndpoints endpoints,
}) async {
  final request = await client.getUrl(authorizeUri);
  request.followRedirects = false;
  _setCommonBrowserHeaders(request, endpoints.matrixURL);
  final response = await request.close();

  final lemonldappdata = _extractCookie(
    response.headers['set-cookie'],
    'lemonldappdata',
  );
  final body = await utf8.decoder.bind(response).join();
  final doc = parse(body);
  final token = doc.querySelector('input[name=token]')?.attributes['value'];
  final url = doc.querySelector('input[name=url]')?.attributes['value'];
  final skin =
      doc.querySelector('input[name=skin]')?.attributes['value'] ?? 'twake';
  if (token == null) {
    throw Exception('Token not found in HTML form');
  }
  if (url == null) {
    throw Exception('url not found in HTML form');
  }
  return _SsoAuthorizeForm(
    token: token,
    url: url,
    skin: skin,
    lemonldappdata: lemonldappdata,
  );
}

/// Result of step 3: POST credentials to SSO `/authorize` and capture the
/// 302 Location's `code` / `session_state` + the `lemonldap` cookie.
class _SsoSubmitResult {
  const _SsoSubmitResult({
    required this.code,
    required this.sessionState,
    required this.lemonldap,
  });
  final String code;
  final String? sessionState;
  final String? lemonldap;
}

Future<_SsoSubmitResult> _submitSsoCredentials({
  required HttpClient client,
  required Uri authorizeUri,
  required _SsoAuthorizeForm form,
  required _Credentials credentials,
}) async {
  final request = await client.postUrl(authorizeUri);
  request.followRedirects = false;
  request.headers
    ..set('Sec-Fetch-Mode', 'navigate')
    ..set(HttpHeaders.refererHeader, authorizeUri.toString())
    ..set('Sec-Fetch-Site', 'same-origin')
    ..set('Origin', 'https://${authorizeUri.host}')
    ..set(HttpHeaders.contentTypeHeader, 'application/x-www-form-urlencoded')
    ..set(
      HttpHeaders.cookieHeader,
      _joinCookies({'lemonldappdata': form.lemonldappdata}),
    )
    ..set(HttpHeaders.userAgentHeader, _userAgent);
  request.write(
    Uri(
      queryParameters: {
        'url': form.url,
        'timezone': '7',
        'skin': form.skin,
        'token': form.token,
        'user': credentials.username,
        'password': credentials.password,
      },
    ).query,
  );
  final response = await request.close();

  final location = response.headers.value('location');
  if (location == null) {
    final body = await utf8.decoder.bind(response).join();
    throw Exception(
      'No redirect after login POST [status=${response.statusCode}] '
      'body=${body.substring(0, body.length.clamp(0, 300))}',
    );
  }
  final params = Uri.parse(location).queryParameters;
  final code = params['code'];
  if (code == null) {
    throw Exception(
      'No code in redirect after login POST – likely wrong credentials.',
    );
  }
  return _SsoSubmitResult(
    code: code,
    sessionState: params['session_state'],
    lemonldap: _extractCookie(response.headers['set-cookie'], 'lemonldap'),
  );
}

Future<String> _exchangeCodeForLoginToken({
  required HttpClient client,
  required _SsoEndpoints endpoints,
  required _OidcRedirect redirect,
  required _SsoSubmitResult submitResult,
}) async {
  final callbackUri =
      Uri.https(endpoints.matrixURL, '/_synapse/client/oidc/callback', {
        'code': submitResult.code,
        'session_state': submitResult.sessionState,
        'state': redirect.params['state'],
      });
  final request = await client.getUrl(callbackUri);
  request.followRedirects = false;
  request.headers
    ..set(HttpHeaders.userAgentHeader, _userAgent)
    ..set(
      HttpHeaders.cookieHeader,
      _joinCookies({
        'oidc_session': redirect.oidcSession,
        'oidc_session_no_samesite': redirect.oidcSession,
        'lemonldap': submitResult.lemonldap,
      }),
    );
  final response = await request.close();

  final loginToken = await _extractLoginTokenFromResponse(response);
  if (loginToken == null) {
    throw Exception('Could not extract loginToken from OIDC callback');
  }
  return loginToken;
}

Future<String?> _extractLoginTokenFromResponse(
  HttpClientResponse response,
) async {
  final location = response.headers.value('location');
  if (location != null) {
    return Uri.parse(location).queryParameters['loginToken'];
  }
  final body = await utf8.decoder.bind(response).join();
  return RegExp(r'loginToken=([^"&\s]+)').firstMatch(body)?.group(1);
}

// ---------------------------------------------------------------------------
// Matrix Client-Server helpers (receiver-side messaging)
// ---------------------------------------------------------------------------

Future<_MatrixSession> _loginWithMLoginToken({
  required HttpClient client,
  required _SsoEndpoints endpoints,
  required String loginToken,
}) async {
  final loginUri = Uri.https(endpoints.matrixURL, '/_matrix/client/v3/login');
  final request = await client.postUrl(loginUri);
  request.headers
    ..set(HttpHeaders.contentTypeHeader, 'application/json')
    ..set(HttpHeaders.userAgentHeader, _userAgent)
    ..set('Origin', 'https://${endpoints.chatURL}');
  request.write(
    jsonEncode({
      'initial_device_display_name': '${endpoints.chatURL}: Chrome on Web',
      'token': loginToken,
      'type': 'm.login.token',
    }),
  );
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Receiver m.login.token failed [status=${response.statusCode}] '
      'body=${body.substring(0, body.length.clamp(0, 300))}',
    );
  }
  final accessToken =
      (jsonDecode(body) as Map<String, dynamic>)['access_token'] as String?;
  if (accessToken == null) {
    throw Exception('Receiver login response missing access_token: $body');
  }
  return _MatrixSession(endpoints: endpoints, accessToken: accessToken);
}

Future<void> _putMatrixMessage({
  required HttpClient client,
  required _MatrixSession session,
  required String groupID,
  required String message,
}) async {
  final endpoints = session.endpoints;
  // Matrix `PUT /send/{eventType}/{txnId}` uses a per-request transaction ID
  // for idempotency. We compose `<chatURL>: Chrome on Web -9-<epoch_ms>` so
  // each retry generates a fresh ID and server logs identify the source run.
  final txnId = Uri.encodeComponent(
    '${endpoints.chatURL}: Chrome on Web -9-'
    '${DateTime.now().millisecondsSinceEpoch}',
  );
  // `groupID` is expected to be a full Matrix room ID (`!localpart:server`)
  // so tests work against any homeserver, not only `linagora.com`. Encode
  // it the same way as `txnId` — `!` and `:` are technically RFC 3986-safe
  // in path segments but the Matrix C-S spec calls for percent-encoding,
  // and some reverse proxies (and federation endpoints) do not tolerate
  // the raw form.
  final encodedRoomId = Uri.encodeComponent(groupID);
  final sendUri = Uri.https(
    endpoints.matrixURL,
    '/_matrix/client/v3/rooms/$encodedRoomId/send/m.room.message/$txnId',
  );
  final request = await client.putUrl(sendUri);
  request.headers
    ..set(HttpHeaders.contentTypeHeader, 'application/json')
    ..set(HttpHeaders.authorizationHeader, 'Bearer ${session.accessToken}')
    ..set(HttpHeaders.userAgentHeader, _userAgent)
    ..set('Origin', 'https://${endpoints.chatURL}');
  request.write(jsonEncode({'msgtype': 'm.text', 'body': message}));
  final response = await request.close();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final body = await utf8.decoder.bind(response).join();
    throw Exception(
      'Receiver send failed [status=${response.statusCode}] '
      'body=${body.substring(0, body.length.clamp(0, 300))}',
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

const _userAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/138.0.0.0 Safari/537.36';

void _setCommonBrowserHeaders(HttpClientRequest request, String host) {
  request.headers
    ..set(HttpHeaders.connectionHeader, 'close')
    ..set('Sec-Fetch-Mode', 'navigate')
    ..set('Sec-Fetch-Site', 'same-site')
    ..set('Sec-Fetch-Dest', 'document')
    ..set(HttpHeaders.hostHeader, host)
    ..set(HttpHeaders.userAgentHeader, _userAgent)
    ..set(
      HttpHeaders.acceptHeader,
      'text/html,application/xhtml+xml,application/xml;q=0.9,'
      'image/avif,image/webp,image/apng,*/*;q=0.8,'
      'application/signed-exchange;v=b3;q=0.7',
    )
    ..set('Upgrade-Insecure-Requests', '1');
}

/// Joins a name→value cookie map into a single `Cookie` header value,
/// silently dropping entries whose value is `null` so the header never
/// contains the literal string `"null"`.
String _joinCookies(Map<String, String?> cookies) => cookies.entries
    .where((e) => e.value != null)
    .map((e) => '${e.key}=${e.value}')
    .join('; ');

String? _extractCookie(List<String>? cookies, String name) {
  if (cookies == null) return null;
  for (final cookie in cookies) {
    final match = RegExp('$name=([^;&]+)').firstMatch(cookie);
    if (match != null) return match.group(1);
  }
  return null;
}
