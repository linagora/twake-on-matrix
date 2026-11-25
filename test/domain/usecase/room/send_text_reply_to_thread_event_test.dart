// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/services/message_splitter.dart';
import 'package:twake_chat/domain/services/room_send_queue_service.dart';
import 'package:twake_chat/domain/usecase/room/send_text_message_interactor.dart';

import '../../../fake_client.dart';
import '../../../lenient_database.dart';

/// Bug (Twake Chat iOS, 2026-11-23/24): a quote reply to a message of a
/// thread went to the main timeline, with `m.in_reply_to` only.
///
/// Need (https://spec.matrix.org/v1.4/client-server-api/#threading): a reply
/// to a message whose `m.relates_to.rel_type` is `m.thread` goes into that
/// thread: `rel_type: m.thread`, `event_id` = the thread root,
/// `is_falling_back: false`, `m.in_reply_to` = the replied message. A reply to
/// a thread root or to a main-timeline message stays a plain reply.
///
/// The reply is sent from the room screen (no thread screen open): the
/// interactor gets no `ThreadSendTarget`, only the replied event.
void main() {
  const rootId = r'$root';
  const threadReplyId = r'$threadReply';
  const mainMessageId = r'$mainMessage';

  late Room room;
  late SendTextMessageInteractor interactor;

  setUpAll(() async {
    final client = await getClient(database: LenientDatabase());
    // FakeMatrixApi answers any send to this room.
    room = Room(
      client: client,
      id: '!1234:fakeServer.notExisting',
      membership: Membership.join,
    );
  });

  setUp(() {
    interactor = SendTextMessageInteractor(
      splitter: const MessageSplitter(maxLength: 1000),
      sendQueue: RoomSendQueueService(),
    );
    FakeMatrixApi.calledEndpoints.clear();
  });

  Event message(String eventId, {Map<String, Object?>? relatesTo}) => Event(
    senderId: '@bob:example.com',
    type: EventTypes.Message,
    room: room,
    eventId: eventId,
    content: {
      'msgtype': MessageTypes.Text,
      'body': 'quoted',
      if (relatesTo != null) 'm.relates_to': relatesTo,
    },
    originServerTs: DateTime.utc(2026, 11, 24),
  );

  Event threadRoot() => message(rootId);

  /// A reply of the thread of [rootId], as another client sends it.
  Event threadReply() => message(
    threadReplyId,
    relatesTo: {
      'rel_type': RelationshipTypes.thread,
      'event_id': rootId,
      'is_falling_back': true,
      'm.in_reply_to': {'event_id': rootId},
    },
  );

  Event mainMessage() => message(mainMessageId);

  /// The content of the one message the app sent to the server.
  Future<Map<String, Object?>> sendAndReadContent({Event? inReplyTo}) async {
    await interactor.execute(
      room: room,
      text: 'my answer',
      inReplyTo: inReplyTo,
    );
    final sent = [
      for (final entry in FakeMatrixApi.calledEndpoints.entries)
        if (entry.key.contains('/send/m.room.message/'))
          for (final body in entry.value)
            (jsonDecode(body as String) as Map).cast<String, Object?>(),
    ];
    expect(sent, hasLength(1), reason: 'one message reached the server');
    return sent.single;
  }

  test('a reply to a message of a thread goes into that thread, quoting '
      'the message', () async {
    final content = await sendAndReadContent(inReplyTo: threadReply());

    expect(content['m.relates_to'], {
      'rel_type': 'm.thread',
      'event_id': rootId,
      'is_falling_back': false,
      'm.in_reply_to': {'event_id': threadReplyId},
    });
  });

  test('a long reply to a message of a thread sends every part into that '
      'thread, each part following the previous one', () async {
    // txn id -> event id the server gave, read from the sync the SDK replays.
    final serverIds = <String, String>{};
    final subscription = room.client.onSync.stream.listen((sync) {
      for (final event
          in sync.rooms?.join?[room.id]?.timeline?.events ?? <MatrixEvent>[]) {
        final txnId = event.unsigned?['transaction_id'];
        if (txnId is String && event.eventId != txnId) {
          serverIds[txnId] = event.eventId;
        }
      }
    });
    addTearDown(subscription.cancel);

    // 2500 characters with a 1000 limit: three parts.
    await interactor.execute(
      room: room,
      text: 'a' * 1000 + 'b' * 1000 + 'c' * 500,
      inReplyTo: threadReply(),
    );

    final parts = [
      for (final entry in FakeMatrixApi.calledEndpoints.entries)
        if (entry.key.contains('/send/m.room.message/'))
          for (final body in entry.value)
            (
              id: serverIds[Uri.decodeComponent(entry.key.split('/').last)],
              content: (jsonDecode(body as String) as Map)
                  .cast<String, Object?>(),
            ),
    ];
    expect(parts, hasLength(3), reason: 'the text was split in three parts');
    expect(parts[0].id, isNotNull);
    expect(parts[1].id, isNotNull);

    expect(parts[0].content['m.relates_to'], {
      'rel_type': 'm.thread',
      'event_id': rootId,
      'is_falling_back': false,
      'm.in_reply_to': {'event_id': threadReplyId},
    }, reason: 'the first part quotes the replied message');
    for (final index in [1, 2]) {
      expect(parts[index].content['m.relates_to'], {
        'rel_type': 'm.thread',
        'event_id': rootId,
        'is_falling_back': true,
        'm.in_reply_to': {'event_id': parts[index - 1].id},
      }, reason: 'part ${index + 1} follows part $index in the thread');
    }
  });

  test('a reply to a thread root stays a plain reply in the room', () async {
    final content = await sendAndReadContent(inReplyTo: threadRoot());

    expect(content['m.relates_to'], {
      'm.in_reply_to': {'event_id': rootId},
    });
  });

  test('a reply to a main-timeline message stays a plain reply', () async {
    final content = await sendAndReadContent(inReplyTo: mainMessage());

    expect(content['m.relates_to'], {
      'm.in_reply_to': {'event_id': mainMessageId},
    });
  });

  test('a message that replies to nothing has no relation', () async {
    final content = await sendAndReadContent();

    expect(content.containsKey('m.relates_to'), isFalse);
  });
}
