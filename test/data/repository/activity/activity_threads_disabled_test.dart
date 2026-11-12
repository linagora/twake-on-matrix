import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

import '../../../providers/fake_active_account.dart';
import '../../datasource_impl/thread/thread_account.dart';

/// THR-M-12, slice 1 (review 2026-11-12): with the threads turned off
/// (`AppConfig.threadsEnabled` false), the app shows no thread: « Replies »
/// lists none, whatever the user followed on the web or wrote in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThreadAccount account;
  late ActivityRepository repository;
  final seen = <List<ActivityItem>>[];
  StreamSubscription<List<ActivityItem>>? subscription;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppConfig.threadsEnabled = false;
    addTearDown(() => AppConfig.threadsEnabled = true);
    account = ThreadAccount(RecordingHomeserver());
    await account.receiveRoomState(const []);
    account.server.answer(
      ServerRoute.get('rooms/$teamRoomId/event/${lunchThread.rootEventId}'),
      {
        ..._message(lunchThread.rootEventId, _bob, 'Lunch on Friday?', 7),
        'room_id': teamRoomId,
        'unsigned': {
          'm.relations': {
            'm.thread': {
              'count': 1,
              'current_user_participated': true,
              'latest_event': {
                ..._reply(r'$ship_it', _bob, 'Ship it', 10),
                'room_id': teamRoomId,
              },
            },
          },
        },
      },
    );
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverrides(account),
    );
    addTearDown(container.dispose);
    repository = container.listen(activityRepositoryProvider, (_, _) {}).read();
  });

  tearDown(() async {
    await subscription?.cancel();
    subscription = null;
    seen.clear();
  });

  Future<List<ActivityItem>> shown() async {
    subscription ??= repository.watchActivity().listen(seen.add);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    var count = -1;
    var quiet = 0;
    while (quiet < 10 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      quiet = seen.length == count ? quiet + 1 : 0;
      count = seen.length;
    }
    expect(seen, isNotEmpty, reason: 'the list emits at once');
    return seen.last;
  }

  test('a thread followed on the web is not in « Replies »', () async {
    await account.receiveThreadPrefs([prefEntry(lunchThread, WirePref.follow)]);

    final items = await shown();

    expect(items.where((item) => item.kind == ActivityKind.reply), isEmpty);
  });

  test('a thread the user wrote in is not in « Replies »', () async {
    await account.receiveSync({
      'rooms': {
        'join': {
          teamRoomId: {
            'timeline': {
              'events': [_reply(r'$mine', threadOwner, 'On it', 11)],
              'limited': false,
            },
          },
        },
      },
    });

    final items = await shown();

    expect(items.where((item) => item.kind == ActivityKind.reply), isEmpty);
  });
}

const _bob = '@bob:example.org';

Map<String, Object?> _message(
  String eventId,
  String sender,
  String body,
  int hour,
) => {
  'type': EventTypes.Message,
  'event_id': eventId,
  'sender': sender,
  'origin_server_ts': DateTime.utc(2026, 11, 12, hour).millisecondsSinceEpoch,
  'content': {'msgtype': 'm.text', 'body': body},
};

Map<String, Object?> _reply(
  String eventId,
  String sender,
  String body,
  int hour,
) => {
  ..._message(eventId, sender, body, hour),
  'content': {
    'msgtype': 'm.text',
    'body': body,
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': lunchThread.rootEventId,
      'is_falling_back': true,
      'm.in_reply_to': {'event_id': lunchThread.rootEventId},
    },
  },
};
