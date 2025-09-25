// ignore_for_file: depend_on_referenced_packages

import 'package:matrix_api_lite/fake_matrix_api.dart';
import 'package:matrix/matrix.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

const ssssPassphrase = 'nae7ahDiequ7ohniufah3ieS2je1thohX4xeeka7aixohsho9O';
const ssssKey = 'EsT9 RzbW VhPW yqNp cC7j ViiW 5TZB LuY4 ryyv 9guN Ysmr WDPH';

Future<Client> getClient() async {
  if (!vod.isInitialized()) {
    await vod.init(
      libraryPath: './vodozemac/debug/',
    );
  }
  final client = Client(
    'testclient',
    httpClient: FakeMatrixApi(),
  );
  await client.checkHomeserver(
    Uri.parse('https://fakeServer.notExisting'),
    checkWellKnown: false,
  );
  await client.init(
    newToken: 'abcd',
    newUserID: '@admin:fakeServer',
    newHomeserver: client.homeserver,
    newDeviceName: 'Text Matrix Client',
    newDeviceID: 'GHTYAJCE',
  );
  await Future.delayed(const Duration(milliseconds: 10));
  return client;
}
