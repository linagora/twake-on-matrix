import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_resolved.dart';

import '../../data/datasource_impl/thread/thread_account.dart';

/// THR-M-08: a thread resolved on the web is resolved on the mobile without
/// reopening the app; another client resolving during a live sync sends the
/// state in the timeline of the sync, a gap brings it in the state section.
/// The resolved state counts in no badge: the badges and the list of rooms,
/// which listen to the thread store, are not redrawn for it (the cards have
/// a signal of their own, thread_resolved_signal_test.dart).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(RecordingHomeserver());
    await _account.receiveRoomState(const []);
  });

  for (final section in RoomSection.values) {
    group('the state in the ${section.name} of a sync', () {
      test('resolves the thread in the room', () async {
        await _account.receiveRoomState([
          resolvedState(lunchThread),
        ], section: section);

        expect(_isResolved, isTrue);
      });

      test('leaves the badges and the list of rooms alone', () async {
        final told = _countNotifications();

        await _account.receiveRoomState([
          resolvedState(lunchThread),
        ], section: section);

        expect(told(), 0);
      });

      test('reopened: the thread is open again', () async {
        await _account.receiveRoomState([resolvedState(lunchThread)]);

        await _account.receiveRoomState([
          reopenedState(lunchThread),
        ], section: section);

        expect(_isResolved, isFalse);
      });
    });
  }
}

late ThreadAccount _account;

bool get _isResolved =>
    _account.getRoomById(teamRoomId)!.isThreadResolved(lunchThread.rootEventId);

/// Counts from now on the times the store tells its listeners.
int Function() _countNotifications() {
  var told = 0;
  _account.threadUnread.addListener(() => told++);
  return () => told;
}
