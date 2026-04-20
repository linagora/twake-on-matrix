import 'dart:convert';

import 'package:http/http.dart' as http;

/// Web implementation of the API login helper.
///
/// On Flutter Web the SSO OIDC bypass used on mobile is not available —
/// browser XHR cannot read the intermediate 302 `Location` headers that the
/// flow depends on, and the SSO origin does not expose CORS for
/// cross-origin XHR anyway. Integration tests therefore run against a
/// locally-provisioned Synapse (see
/// `scripts/integration-test-provision-synapse.sh`) that accepts
/// `m.login.password` on its client-server API. Matrix homeservers serve
/// that endpoint with permissive CORS — the same way Element Web relies on
/// it — so `package:http`'s browser client can call it directly.
///
/// The function returns a Matrix **access token** (not a one-time
/// `loginToken`); the caller is expected to inject it into the Matrix
/// client rather than feeding it through the `/onAuthRedirect` deep link.
Future<String> fetchOidcLoginToken({
  required String username,
  required String password,
}) async {
  const matrixURL = String.fromEnvironment('MATRIX_URL');
  final loginUri = Uri.parse('$matrixURL/_matrix/client/v3/login');

  final response = await http.post(
    loginUri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'type': 'm.login.password',
      'identifier': {'type': 'm.id.user', 'user': username},
      'password': password,
      'initial_device_display_name': 'patrol-web-integration-test',
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Matrix login failed [${response.statusCode}]: ${response.body}',
    );
  }
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final accessToken = body['access_token'] as String?;
  if (accessToken == null || accessToken.isEmpty) {
    throw Exception(
      'Matrix login response missing access_token: ${response.body}',
    );
  }
  return accessToken;
}

/// Sends a message as the `Receiver` account by first obtaining its access
/// token via `m.login.password`, then `PUT`-ing the event to the configured
/// `GroupID`.
Future<void> sendMessageAsReceiver({required String message}) async {
  const matrixURL = String.fromEnvironment('MATRIX_URL');
  const receiver = String.fromEnvironment('Receiver');
  const passOfReceiver = String.fromEnvironment('ReceiverPass');
  const groupID = String.fromEnvironment('GroupID');

  final accessToken = await fetchOidcLoginToken(
    username: receiver,
    password: passOfReceiver,
  );

  final sendUri = Uri.parse(
    '$matrixURL/_matrix/client/v3/rooms/$groupID/send/m.room.message/'
    'patrol-web-${DateTime.now().millisecondsSinceEpoch}',
  );
  final response = await http.put(
    sendUri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode({'msgtype': 'm.text', 'body': message}),
  );
  if (response.statusCode != 200) {
    throw Exception(
      'sendMessage failed [${response.statusCode}]: ${response.body}',
    );
  }
}
