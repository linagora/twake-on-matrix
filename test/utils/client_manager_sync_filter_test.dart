import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/client_manager.dart';

/// THR-M-06: the sync filter asks the server for per-thread unread counters.
void main() {
  Map<String, Object?> roomFilterJson() =>
      ClientManager.syncFilter.toJson()['room'] as Map<String, Object?>;

  test(
    'the sync filter enables unread_thread_notifications on the timeline',
    () {
      final timeline = roomFilterJson()['timeline'] as Map<String, Object?>?;

      expect(timeline?['unread_thread_notifications'], isTrue);
    },
  );

  test('the sync filter still includes left rooms and lazy-loads members', () {
    final room = roomFilterJson();

    expect(room['include_leave'], isTrue);
    expect(
      (room['state'] as Map<String, Object?>?)?['lazy_load_members'],
      isTrue,
    );
  });
}
