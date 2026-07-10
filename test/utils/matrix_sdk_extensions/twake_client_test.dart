import 'package:fluffychat/utils/matrix_sdk_extensions/twake_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_client.dart';

void main() {
  test('enables limited timeline history backfill before initialization', () {
    final client = TwakeClient('testclient', database: MockDatabase());

    expect(client.requestHistoryOnLimitedTimeline, isTrue);
  });
}
