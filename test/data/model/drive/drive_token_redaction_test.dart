import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/model/drive/drive_token_exchange_request.dart';
import 'package:twake_chat/data/model/drive/drive_token_exchange_response.dart';

void _requestNeverPrintsTheIdToken() {
  final request = DriveTokenExchangeRequest.app(idToken: 'secret-id-token');

  expect('$request', isNot(contains('secret-id-token')));
}

void _responseNeverPrintsTheAccessToken() {
  const response = DriveTokenExchangeResponse(accessToken: 'secret-access');

  expect('$response', isNot(contains('secret-access')));
}

void main() {
  test('request never prints the id token', _requestNeverPrintsTheIdToken);
  test(
    'response never prints the access token',
    _responseNeverPrintsTheAccessToken,
  );
}
