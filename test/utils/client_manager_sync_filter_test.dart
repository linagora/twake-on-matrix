import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/client_manager.dart';

/// THR-M-06: the sync filter asks the server for per-thread unread counters.
/// Review of #3608 (nqhhdev): `AppConfig.threadsEnabled` gates this level;
/// off, the filter is the one of before threads, so the server keeps the
/// thread replies in the room counters.
///
/// Both states in one file: the filter must follow the flag when it is read,
/// not when it was first built.
void main() {
  late bool flagBefore;

  setUp(() => flagBefore = AppConfig.threadsEnabled);
  tearDown(() => AppConfig.threadsEnabled = flagBefore);

  Map<String, Object?> roomFilterJson() =>
      ClientManager.syncFilter.toJson()['room'] as Map<String, Object?>;

  void expectLeftRoomsAndLazyMembers() {
    final room = roomFilterJson();

    expect(room['include_leave'], isTrue);
    expect(
      (room['state'] as Map<String, Object?>?)?['lazy_load_members'],
      isTrue,
    );
  }

  group('with threads off', () {
    setUp(() => AppConfig.threadsEnabled = false);

    test('the sync filter does not ask for unread_thread_notifications', () {
      final timeline = roomFilterJson()['timeline'] as Map<String, Object?>?;

      expect(timeline?['unread_thread_notifications'], isNot(isTrue));
    });

    test(
      'the sync filter still includes left rooms and lazy-loads members',
      expectLeftRoomsAndLazyMembers,
    );
  });

  group('with threads on', () {
    setUp(() => AppConfig.threadsEnabled = true);

    test(
      'the sync filter enables unread_thread_notifications on the timeline',
      () {
        final timeline = roomFilterJson()['timeline'] as Map<String, Object?>?;

        expect(timeline?['unread_thread_notifications'], isTrue);
      },
    );

    test(
      'the sync filter still includes left rooms and lazy-loads members',
      expectLeftRoomsAndLazyMembers,
    );
  });
}
