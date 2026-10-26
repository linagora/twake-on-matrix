import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sticker_fixture.dart';

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
Future<String> fetchAuthToken({
  required String username,
  required String password,
}) async {
  const matrixURL = String.fromEnvironment('MATRIX_URL');
  if (matrixURL.isEmpty) {
    throw StateError('Missing required --dart-define=MATRIX_URL');
  }
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

/// Sends a message as the `Receiver` account to [roomId] or the configured
/// `GroupID`.
Future<void> sendMessageAsReceiver({required String message, String? roomId}) =>
    _putEventAsReceiver(
      roomId: roomId,
      eventType: 'm.room.message',
      content: (_) async => {'msgtype': 'm.text', 'body': message},
    );

Future<void> sendMessagesAsReceiver({
  required List<String> messages,
  String? roomId,
}) async {
  for (final message in messages) {
    await sendMessageAsReceiver(message: message, roomId: roomId);
  }
}

/// Sends an `m.sticker` event as the `Receiver` account. Twake cannot send
/// stickers itself, so tests use this to receive one like from Element.
Future<void> sendStickerAsReceiver({
  required String body,
  required String roomId,
}) => _putEventAsReceiver(
  roomId: roomId,
  eventType: 'm.sticker',
  content: (accessToken) async => stickerFixtureContent(
    body: body,
    url: await _uploadStickerFixture(accessToken),
  ),
);

const _matrixURL = String.fromEnvironment('MATRIX_URL');

Future<String> _uploadStickerFixture(String accessToken) async {
  final upload = await http.post(
    Uri.parse('$_matrixURL/_matrix/media/v3/upload'),
    headers: {
      'Content-Type': stickerFixtureMimeType,
      'Authorization': 'Bearer $accessToken',
    },
    body: stickerFixtureBytes,
  );
  if (!_isSuccess(upload.statusCode)) {
    throw Exception(
      'Sticker upload failed [${upload.statusCode}]: ${upload.body}',
    );
  }
  return (jsonDecode(upload.body) as Map<String, dynamic>)['content_uri']
      as String;
}

/// Logs the `Receiver` account in, then `PUT`s an [eventType] event built by
/// [content] to [roomId] or the configured `GroupID`.
Future<void> _putEventAsReceiver({
  required String? roomId,
  required String eventType,
  required Future<Map<String, Object?>> Function(String accessToken) content,
}) async {
  const receiver = String.fromEnvironment('Receiver');
  const passOfReceiver = String.fromEnvironment('ReceiverPass');
  const groupID = String.fromEnvironment('GroupID');
  final targetRoom = roomId ?? groupID;
  if (_matrixURL.isEmpty ||
      receiver.isEmpty ||
      passOfReceiver.isEmpty ||
      targetRoom.isEmpty) {
    throw StateError(
      'Missing required dart-defines: MATRIX_URL/Receiver/ReceiverPass/GroupID',
    );
  }

  final accessToken = await fetchAuthToken(
    username: receiver,
    password: passOfReceiver,
  );
  final body = await content(accessToken);

  final encodedRoomId = Uri.encodeComponent(targetRoom);
  final response = await http.put(
    Uri.parse(
      '$_matrixURL/_matrix/client/v3/rooms/$encodedRoomId/send/$eventType/'
      'patrol-web-${DateTime.now().millisecondsSinceEpoch}',
    ),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode(body),
  );
  if (!_isSuccess(response.statusCode)) {
    throw Exception(
      'Sending $eventType failed [${response.statusCode}]: ${response.body}',
    );
  }
}

bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

/// Mobile group fixtures create rooms on the device client. Web tests use
/// the pre-provisioned Synapse [GroupID] and never invite the receiver.
Future<void> ensureReceiverJoined({required String roomId}) async {
  throw UnsupportedError(
    'ensureReceiverJoined is only used by mobile group fixtures',
  );
}
