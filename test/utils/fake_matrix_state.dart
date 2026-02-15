import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../fake_client.dart';

class FakeMatrixState extends Fake implements MatrixState {
  @override
  final Client client;

  FakeMatrixState(this.client);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FakeMatrixState';
  }
}

Future<FakeMatrixState> getFakeMatrixState() async {
  final client = await getClient();
  return FakeMatrixState(client);
}
