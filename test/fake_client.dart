// ignore_for_file: depend_on_referenced_packages

import 'package:matrix_api_lite/fake_matrix_api.dart';
import 'package:matrix/matrix.dart';

const ssssPassphrase = 'nae7ahDiequ7ohniufah3ieS2je1thohX4xeeka7aixohsho9O';
const ssssKey = 'EsT9 RzbW VhPW yqNp cC7j ViiW 5TZB LuY4 ryyv 9guN Ysmr WDPH';

// key @test:fakeServer.notExisting
const pickledOlmAccount =
    'N2v1MkIFGcl0mQpo2OCwSopxPQJ0wnl7oe7PKiT4141AijfdTIhRu+ceXzXKy3Kr00nLqXtRv7kid6hU4a+V0rfJWLL0Y51+3Rp/ORDVnQy+SSeo6Fn4FHcXrxifJEJ0djla5u98fBcJ8BSkhIDmtXRPi5/oJAvpiYn+8zMjFHobOeZUAxYR0VfQ9JzSYBsSovoQ7uFkNks1M4EDUvHtuyg3RxViwdNxs3718fyAqQ/VSwbXsY0Nl+qQbF+nlVGHenGqk5SuNl1P6e1PzZxcR0IfXA94Xij1Ob5gDv5YH4UCn9wRMG0abZsQP0YzpDM0FLaHSCyo9i5JD/vMlhH+nZWrgAzPPCTNGYewNV8/h3c+VyJh8ZTx/fVi6Yq46Fv+27Ga2ETRZ3Qn+Oyx6dLBjnBZ9iUvIhqpe2XqaGA1PopOz8iDnaZitw';

Future<Client> getClient() async {
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
    newUserID: '@test:fakeServer.notExisting',
    newHomeserver: client.homeserver,
    newDeviceName: 'Text Matrix Client',
    newDeviceID: 'GHTYAJCE',
    newOlmAccount: pickledOlmAccount,
  );
  await Future.delayed(const Duration(milliseconds: 10));
  return client;
}
