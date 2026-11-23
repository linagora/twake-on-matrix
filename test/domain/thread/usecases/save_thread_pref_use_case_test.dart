import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/exception/thread/thread_change_exception.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/thread/usecases/save_thread_pref_use_case.dart';

import '../fake_thread_prefs_repository.dart';

/// THR-M-07: follow, unfollow, mute and unmute are one choice saved in the
/// account (unmute saves « follow », as on the web).
void main() {
  late FakeThreadPrefsRepository repository;
  late SaveThreadPrefUseCase saveThreadPref;

  setUp(() {
    repository = FakeThreadPrefsRepository();
    saveThreadPref = SaveThreadPrefUseCase(repository);
  });
  tearDown(() => repository.close());

  for (final pref in ThreadPref.values) {
    test('« ${pref.name} » is saved for the thread', () async {
      await saveThreadPref.execute(lunchThread, pref);

      expect(repository.changes, [PrefSaved(lunchThread, pref)]);
    });
  }

  test('a choice the account refuses fails', () async {
    repository.isDown = true;

    await expectLater(
      saveThreadPref.execute(lunchThread, ThreadPref.mute),
      throwsA(isA<ThreadChangeFailedException>()),
    );
  });
}
