import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/utils/background_push.dart';

import 'icon_badge/icon_badge_fakes.dart';

/// Issue #3635: the push service keeps the iOS icon badge on the app's
/// count. Opening a room (`cancelNotification`) and the syncs of the account
/// served write it with one rule; the rule itself is specified in
/// test/utils/icon_badge/icon_badge_updater_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool flagBefore;
  late BadgeAccount first;
  late BadgeAccount second;
  late RecordedIconBadge badge;
  late BackgroundPush push;

  setUp(() async {
    flagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
    SharedPreferences.setMockInitialValues({});
    await appInForeground();
    first = BadgeAccount();
    second = BadgeAccount();
    badge = RecordedIconBadge();
    // The service is a singleton: each test starts from a known client.
    push = BackgroundPush.clientOnly(first)
      ..rebind(first)
      ..useIconBadge(badge, onIos: true);
  });

  tearDown(() => AppConfig.threadsEnabled = flagBefore);

  test('opening a room writes the count of the other rooms', () async {
    first.joined(_general).notificationCount = 1;
    first.joined(_random).notificationCount = 1;

    await push.cancelNotification(_general.value);

    expect(badge.writes, [1]);
  });

  test('a sync of the account served writes its count', () async {
    final general = first.joined(_general)..notificationCount = 1;

    await first.syncs(general);

    expect(badge.writes, [1]);
  });

  test(
    'after a rebind, only the syncs of the account now served write',
    () async {
      final before = first.joined(_general)..notificationCount = 1;
      final now = second.joined(_random);
      push.rebind(second);

      await first.syncs(before);
      expect(badge.writes, isEmpty);

      await second.syncs(now);
      expect(badge.writes, [removed]);
    },
  );
}

const _general = RoomId('!general:example.com');
const _random = RoomId('!random:example.com');
