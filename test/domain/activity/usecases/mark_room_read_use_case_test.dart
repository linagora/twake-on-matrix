import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/activity/usecases/mark_room_read_use_case.dart';

import '../../../pages/activity/activity_test_support.dart';

/// ADR 0037 §5 (review of PR #3624, jbrnzl): « Mark as read » of the
/// Activity tab goes through a use case over the activity repository: it
/// reads the main timeline of the room and its threads.
void main() {
  late FakeActivityRepository repository;
  late MarkRoomReadUseCase markRoomRead;

  const design = '!design:example.org';

  setUp(() {
    repository = FakeActivityRepository();
    markRoomRead = MarkRoomReadUseCase(repository);
  });
  tearDown(() => repository.close());

  test('reads the room', () async {
    await markRoomRead.execute(design);

    expect(repository.markedRead, [design]);
  });

  test('a room that cannot be read fails', () async {
    final offline = Exception('offline');
    repository.markReadError = offline;

    await expectLater(markRoomRead.execute(design), throwsA(same(offline)));
  });
}
