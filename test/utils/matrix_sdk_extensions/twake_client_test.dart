import 'package:twake_chat/utils/matrix_sdk_extensions/twake_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

void main() {
  test('enables limited timeline history backfill before initialization', () {
    final client = TwakeClient('testclient', database: MockDatabase());

    expect(client.requestHistoryOnLimitedTimeline, isTrue);
  });

  test('keeps call events out of the room preview', () {
    final client = TwakeClient('testclient', database: MockDatabase());

    expect(
      client.roomPreviewLastEvents,
      containsAll([EventTypes.Message, EventTypes.Encrypted]),
    );
    expect(
      client.roomPreviewLastEvents,
      isNot(contains(EventTypes.CallInvite)),
    );
    expect(
      client.roomPreviewLastEvents,
      isNot(contains(EventTypes.GroupCallMember)),
    );
  });
}
