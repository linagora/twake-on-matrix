import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/repository/activity/activity_mentions_repository.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';

import '../../../providers/fake_active_account.dart';
import '../../datasource_impl/thread/thread_account.dart';

/// THR-M-12, slice 2, found on the real app (QA 2026-11-12): the badge
/// counted a new mention while the open list « Mentions » kept the old
/// ones. With the sync and `/notifications` of the account: a sync that
/// changes the unread mentions count reads the mentions again; a sync that
/// leaves it as it is reads nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const notifications = ServerRoute.get('notifications');

  late ThreadAccount account;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    account = ThreadAccount(RecordingHomeserver());
    await account.receiveRoomState(const []);
    await _syncTeam(account, highlights: 0);
    account.server.answer(notifications, _notifications([_ask]));
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverrides(account),
    );
    addTearDown(container.dispose);
  });

  /// The list « Mentions » is open: the count and the mentions are watched.
  Future<List<ActivityItem>> mentionsShown() async {
    container.listen(unreadMentionCountProvider, (_, _) {});
    container.listen(activityMentionsProvider, (_, _) {});
    await _settle();
    return container.read(activityMentionsProvider.future);
  }

  test('a sync that brings a new mention reads the mentions again', () async {
    expect((await mentionsShown()).map((m) => m.eventId), [r'$ask']);
    final readsBefore = account.server.callsTo(notifications).length;

    account.server.answer(notifications, _notifications([_budget, _ask]));
    await _syncTeam(account, highlights: 1);
    await _settle();

    expect(account.server.callsTo(notifications).length, readsBefore + 1);
    expect(
      (await container.read(
        activityMentionsProvider.future,
      )).map((m) => m.eventId),
      [r'$budget', r'$ask'],
    );
  });

  test('a sync that leaves the count as it is reads nothing', () async {
    await mentionsShown();
    await _syncTeam(account, highlights: 1);
    await _settle();
    final readsAfterChange = account.server.callsTo(notifications).length;

    await _syncTeam(account, highlights: 1);
    await _settle();

    expect(account.server.callsTo(notifications).length, readsAfterChange);
  });
}

const _dan = '@dan:example.org';

DateTime _at(int hour, [int minute = 0]) =>
    DateTime.utc(2026, 11, 12, hour, minute);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 1300));

Map<String, Object?> _message(String eventId, String body, DateTime at) => {
  'type': EventTypes.Message,
  'event_id': eventId,
  'sender': _dan,
  'room_id': teamRoomId,
  'origin_server_ts': at.millisecondsSinceEpoch,
  'content': {'msgtype': 'm.text', 'body': body},
};

final _ask = _message(r'$ask', '@me can you check?', _at(9));
final _budget = _message(r'$budget', '@me the budget is in', _at(11));

/// `GET /notifications`: [events], newest first, each highlighted.
Map<String, Object?> _notifications(List<Map<String, Object?>> events) => {
  'notifications': [
    for (final event in events)
      {
        'actions': [
          'notify',
          {'set_tweak': 'highlight'},
        ],
        'event': event,
        'read': false,
        'room_id': teamRoomId,
        'ts': event['origin_server_ts'],
      },
  ],
};

Future<void> _syncTeam(ThreadAccount account, {required int highlights}) =>
    account.receiveSync({
      'rooms': {
        'join': {
          teamRoomId: {
            'state': {
              'events': [
                {
                  'type': EventTypes.RoomMember,
                  'state_key': _dan,
                  'sender': _dan,
                  'event_id': r'$member_dan',
                  'origin_server_ts': _at(7).millisecondsSinceEpoch,
                  'content': {'membership': 'join', 'displayname': 'Dan Brown'},
                },
              ],
            },
            'unread_notifications': {
              'notification_count': highlights,
              'highlight_count': highlights,
            },
          },
        },
      },
    });
