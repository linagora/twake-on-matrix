import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/manager/upload_manager/pending_upload_order.dart';

void main() {
  late PendingUploadOrder order;
  late List<String> joined;

  setUp(() {
    order = PendingUploadOrder();
    joined = [];
  });

  Future<void> give(String roomId, Completer<String> bytes) =>
      order.inTurn(roomId, bytes.future, joined.add);

  test('a file that arrives first still joins after the one shown before '
      'it', () async {
    final big = Completer<String>();
    final small = Completer<String>();
    final first = give('!room', big);
    final second = give('!room', small);

    small.complete('small');
    await pumpEventQueue();
    expect(joined, isEmpty);

    big.complete('big');
    await Future.wait([first, second]);
    expect(joined, ['big', 'small']);
  });

  test('a file that fails lets the next one through', () async {
    final failed = Completer<String>();
    final next = Completer<String>();
    final first = give('!room', failed);
    final second = give('!room', next);

    next.complete('next');
    failed.completeError(StateError('download failed'));

    await expectLater(first, throwsStateError);
    await second;
    expect(joined, ['next']);
  });

  test(
    'a file after a failed one still waits for the ones before it',
    () async {
      final slow = Completer<String>();
      final failed = Completer<String>();
      final fast = Completer<String>()..complete('fast');
      final first = give('!room', slow);
      final second = give('!room', failed);
      final third = give('!room', fast);

      failed.completeError(StateError('download failed'));
      await expectLater(second, throwsStateError);
      await pumpEventQueue();
      expect(joined, isEmpty);

      slow.complete('slow');
      await Future.wait([first, third]);
      expect(joined, ['slow', 'fast']);
    },
  );

  test(
    'a file given after a failed last one waits for a slow one before',
    () async {
      final slow = Completer<String>();
      final failed = Completer<String>();
      final first = give('!room', slow);
      final second = give('!room', failed);
      failed.completeError(StateError('download failed'));
      await expectLater(second, throwsStateError);

      final late = give('!room', Completer<String>()..complete('late'));
      await pumpEventQueue();
      expect(joined, isEmpty);

      slow.complete('slow');
      await Future.wait([first, late]);
      expect(joined, ['slow', 'late']);
    },
  );

  test('a file of another room does not wait', () async {
    final slow = Completer<String>();
    final other = Completer<String>()..complete('other');
    unawaited(give('!room', slow));

    await give('!other', other);
    expect(joined, ['other']);
    slow.complete('slow');
  });
}
