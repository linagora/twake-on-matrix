import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/datasource_impl/thread/thread_prefs_datasource_impl.dart';
import 'package:twake_chat/domain/exception/thread/thread_change_exception.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/pages/chat/thread/thread_menu_controller.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

import '../../../data/datasource_impl/thread/thread_account.dart';

/// THR-M-07, review of P2: the user logs out (the session is cleared) while
/// a choice of the « ⋮ » menu is being saved. The save fails as any failure
/// does: the menu says « The thread could not be changed. » and can be used
/// again; no error is left unhandled.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _server = RecordingHomeserver();
    _account = ThreadAccount(_server);
    await _account.start();
  });

  test('the save fails with the failure the menu tells', () async {
    final save = _whileLoggingOut(
      () => ThreadPrefsDatasourceImpl(
        _account,
      ).saveThreadPref(lunchThread, ThreadPref.mute),
    );

    await expectLater(save, throwsA(isA<ThreadChangeFailedException>()));
  });

  group('the menu', () {
    late ProviderContainer container;
    final provider = threadMenuControllerProvider(lunchThread);

    setUp(() async {
      container = ProviderContainer.test(
        overrides: [activeMatrixClientProvider.overrideWithValue(_account)],
      );
      container.listen(provider, (_, _) {});
      await pumpEventQueue();
    });

    Future<bool> mute() =>
        _whileLoggingOut(container.read(provider.notifier).mute);

    test('tells the choice was not saved', () async {
      expect(await mute(), isFalse);
    });

    test('can be used again', () async {
      // Whatever the save gives; the menu after it is the subject.
      await mute().catchError((_) => false);

      expect(container.read(provider).isSaving, isFalse);
    });
  });
}

late RecordingHomeserver _server;
late ThreadAccount _account;

/// Starts [save] on a network slow to silence the thread; meanwhile the
/// user logs out, then the server answers. Gives what the save gives.
Future<T> _whileLoggingOut<T>(Future<T> Function() save) async {
  _server.hold(threadRuleWrite);
  final saving = save();
  await pumpEventQueue();
  await _account.clear();
  _server.release(threadRuleWrite);
  return saving;
}
