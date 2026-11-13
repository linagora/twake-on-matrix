import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/datasource_impl/thread/thread_prefs_datasource_impl.dart';
import 'package:twake_chat/domain/model/thread/thread_status.dart';
import 'package:twake_chat/pages/chat/thread/thread_menu_controller.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

import 'thread_account.dart';

/// THR-M-08, review of P2: at startup the rooms come from the device, partly
/// loaded until the room is opened. A thread resolved on the web (state
/// `app.twake.chat.thread_resolved` stored on the device) shows resolved in
/// its menu and its header at once, without waiting for a sync.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(
      RecordingHomeserver(),
      storedTeamRoomStates: [
        resolvedState(lunchThread),
        reopenedState(releaseThread),
      ],
    );
    await _account.start();
  });

  test(
    'the first status of a thread resolved on the web says resolved',
    () async {
      final first = await _datasource.watchThread(lunchThread).first;

      expect(first.isResolved, isTrue);
    },
  );

  test('a thread reopened on the web shows open', () async {
    final first = await _datasource.watchThread(releaseThread).first;

    expect(first.isResolved, isFalse);
  });

  test('the header of the thread says resolved', () async {
    final container = ProviderContainer.test(
      overrides: [activeMatrixClientProvider.overrideWithValue(_account)],
    );
    final provider = threadMenuControllerProvider(lunchThread);
    container.listen(provider, (_, _) {});
    await pumpEventQueue();

    expect(container.read(provider).status?.isResolved, isTrue);
  });

  test('resolved on the web while the app runs, the room never opened: the '
      'thread shows resolved', () async {
    final seen = <ThreadStatus>[];
    final watching = _datasource.watchThread(releaseThread).listen(seen.add);
    addTearDown(watching.cancel);
    await pumpEventQueue();

    await _account.receiveRoomState([
      resolvedState(releaseThread),
    ], section: RoomSection.timeline);
    await pumpEventQueue();

    expect(seen.last.isResolved, isTrue);
  });
}

late ThreadAccount _account;

ThreadPrefsDatasourceImpl get _datasource =>
    ThreadPrefsDatasourceImpl(_account);
