// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/repository/activity/activity_mentions_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_mentions_repository.dart';

import 'activity_sync_events.dart';
import '../../../providers/fake_active_account.dart';
import '../../datasource_impl/thread/thread_account.dart';

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md), slice 2: the
/// mentions come from `/notifications` (`getNotifications`, api.dart:2998),
/// which also covers the history not loaded. A mention is a notification
/// the server highlighted; one in a thread carries its thread (it opens
/// there) and the start of its root.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _server = _NotificationsServer();
    _account = ThreadAccount(_server);
    // The room open on screen: all its states (the members) held.
    await _account.receiveRoomState(const []);
    await _account.receiveSync({
      'rooms': {
        'join': {
          teamRoomId: {
            'state': {
              'events': [
                teamNameEvent,
                memberEvent((id: threadOwner, name: 'Me Myself')),
                memberEvent((id: _dan, name: 'Dan Brown')),
              ],
            },
          },
        },
      },
    });
    _server.answer(
      ServerRoute.get('rooms/$teamRoomId/event/${lunchThread.rootEventId}'),
      {
        ...messageEvent((
          id: lunchThread.rootEventId,
          sender: _dan,
          body: 'Lunch on Friday? Pick a place',
          at: 7.utc,
        )),
        'room_id': teamRoomId,
      },
    );
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverrides(_account),
    );
    addTearDown(container.dispose);
    _repository = container
        .listen(activityMentionsRepositoryProvider, (_, _) {})
        .read();
  });

  test('a mention in a room: who, the room, the message and when', () async {
    _server.notifications = [
      _notification(
        messageEvent((
          id: r'$ask',
          sender: _dan,
          body: '@me can you check?',
          at: 9.utc,
        )),
        _Seen.mention,
      ),
    ];

    final mention = (await _repository.getMentions()).single;

    expect(mention.kind, ActivityKind.mention);
    expect(mention.roomId, teamRoomId);
    expect(mention.roomName, 'Team');
    expect(mention.authorName, 'Dan Brown');
    expect(mention.quote, '@me can you check?');
    expect(mention.eventId, r'$ask');
    expect(mention.time, sameInstant(9.utc));
    expect(mention.threadRootId, isNull);
  });

  test('a mention in a thread carries its thread and the start of its '
      'root', () async {
    _server.notifications = [
      _notification(
        threadReplyEvent((
          id: r'$in_thread',
          sender: _dan,
          body: '@me what do you think?',
          at: (9, 30).utc,
        ), lunchThread),
        _Seen.mention,
      ),
    ];

    final mention = (await _repository.getMentions()).single;

    expect(mention.eventId, r'$in_thread');
    expect(mention.threadRootId, lunchThread.rootEventId);
    expect(mention.threadTitle, startsWith('Lunch on Friday'));
  });

  test(
    'a notification the server did not highlight is not a mention',
    () async {
      _server.notifications = [
        _notification(
          messageEvent((
            id: r'$plain',
            sender: _dan,
            body: 'lunch is ready',
            at: 9.utc,
          )),
          _Seen.plain,
        ),
        _notification(
          messageEvent((
            id: r'$ask',
            sender: _dan,
            body: '@me can you check?',
            at: 10.utc,
          )),
          _Seen.mention,
        ),
      ];

      final mentions = await _repository.getMentions();

      expect(mentions.map((m) => m.eventId), [r'$ask']);
    },
  );

  test('a mention already read is still listed', () async {
    _server.notifications = [
      _notification(
        messageEvent((
          id: r'$ask',
          sender: _dan,
          body: '@me can you check?',
          at: 9.utc,
        )),
        _Seen.readMention,
      ),
    ];

    expect(await _repository.getMentions(), hasLength(1));
  });

  test('no mention: an empty list', () async {
    _server.notifications = [];

    expect(await _repository.getMentions(), isEmpty);
  });

  test('when the server cannot be reached, reading the mentions fails, so '
      'the screen can say so', () async {
    _server.failNotifications = true;

    await expectLater(_repository.getMentions(), throwsA(anything));
  });
}

late ThreadAccount _account;
late _NotificationsServer _server;
late ActivityMentionsRepository _repository;

const _dan = '@dan:example.org';

/// `GET /notifications` answers [notifications], honouring `only=highlight`
/// as Synapse does; every other route is the [RecordingHomeserver]'s.
class _NotificationsServer extends RecordingHomeserver {
  List<Map<String, Object?>> notifications = [];
  bool failNotifications = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!request.url.path.endsWith('/notifications')) {
      return super.send(request);
    }
    calls.add(ServerCall(request));
    if (failNotifications) {
      return _json(500, {'errcode': 'M_UNKNOWN', 'error': 'down'});
    }
    final onlyHighlights = request.url.queryParameters['only'] == 'highlight';
    return _json(200, {
      'notifications': [
        for (final notification in notifications)
          if (!onlyHighlights || notification['_highlight'] == true)
            {...notification}..remove('_highlight'),
      ],
    });
  }

  static http.StreamedResponse _json(int status, Object body) =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(body))),
        status,
        headers: {'content-type': 'application/json'},
      );
}

/// How the server tells a notification: a mention (highlighted), read or
/// not, or a plain notification.
enum _Seen { mention, readMention, plain }

Map<String, Object?> _notification(Map<String, Object?> event, _Seen seen) {
  final highlight = seen != _Seen.plain;
  return {
    '_highlight': highlight,
    'actions': [
      'notify',
      if (highlight) {'set_tweak': 'highlight'},
      {'set_tweak': 'sound', 'value': 'default'},
    ],
    'event': {...event, 'room_id': teamRoomId},
    'read': seen == _Seen.readMention,
    'room_id': teamRoomId,
    'ts': event['origin_server_ts'],
  };
}
