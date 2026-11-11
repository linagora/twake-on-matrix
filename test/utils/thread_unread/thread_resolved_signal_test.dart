import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasource_impl/thread/thread_account.dart';

/// THR-M-08: a thread resolved on the web shows « Resolved » on its card
/// under the root without reopening the app. The cards redraw on a signal
/// of the thread store kept for the resolved state,
/// `ThreadUnreadStore.resolvedChanges`, so the badges and the list of rooms
/// are not redrawn for it (thread_resolved_redraw_test.dart).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(RecordingHomeserver());
    await _account.receiveRoomState(const []);
  });

  for (final section in RoomSection.values) {
    group('the state in the ${section.name} of a sync', () {
      test('redraws the cards', () async {
        final told = _countResolvedChanges();

        await _account.receiveRoomState([
          resolvedState(lunchThread),
        ], section: section);

        expect(told(), isPositive);
      });

      test('reopened: redraws the cards again', () async {
        await _account.receiveRoomState([resolvedState(lunchThread)]);
        final told = _countResolvedChanges();

        await _account.receiveRoomState([
          reopenedState(lunchThread),
        ], section: section);

        expect(told(), isPositive);
      });
    });
  }

  test('a sync without any thread state leaves the cards alone', () async {
    final told = _countResolvedChanges();

    await _account.receiveRoomState([
      powerLevels({'state_default': 50}),
    ], section: RoomSection.timeline);

    expect(told(), 0);
  });
}

late ThreadAccount _account;

/// Counts from now on the times the cards are told a resolved state changed.
int Function() _countResolvedChanges() {
  var told = 0;
  final Listenable signal = _account.threadUnread.resolvedChanges;
  signal.addListener(() => told++);
  return () => told;
}
