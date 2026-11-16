import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/exception/thread/thread_change_exception.dart';
import 'package:twake_chat/domain/thread/usecases/save_thread_resolved_use_case.dart';

import '../fake_thread_prefs_repository.dart';

/// THR-M-08: « Mark as resolved » and « Reopen the thread » save the
/// resolved state of the thread in its room.
void main() {
  late FakeThreadPrefsRepository repository;
  late SaveThreadResolvedUseCase saveThreadResolved;

  setUp(() {
    repository = FakeThreadPrefsRepository();
    saveThreadResolved = SaveThreadResolvedUseCase(repository);
  });
  tearDown(() => repository.close());

  test('resolving saves the thread resolved', () async {
    await saveThreadResolved.execute(lunchThread, resolved: true);

    expect(repository.changes, [
      const ResolvedSaved(lunchThread, resolved: true),
    ]);
  });

  test('reopening saves the thread open', () async {
    await saveThreadResolved.execute(lunchThread, resolved: false);

    expect(repository.changes, [
      const ResolvedSaved(lunchThread, resolved: false),
    ]);
  });

  test('a state the room refuses fails', () async {
    repository.isDown = true;

    await expectLater(
      saveThreadResolved.execute(lunchThread, resolved: true),
      throwsA(isA<ThreadChangeFailedException>()),
    );
  });
}
