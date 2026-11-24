// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:twake_chat/data/model/media/upload_file_json.dart';
import 'package:twake_chat/data/network/media/media_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_worker_queue.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_send_target.dart';
import 'package:twake_chat/utils/task_queue/task.dart';

import '../../../fake_client.dart';
import '../../../lenient_database.dart';

/// Records the queued tasks; the test runs them when it wants the send.
class _RecordingQueue extends UploadWorkerQueue {
  final List<Task> added = [];

  @override
  Future addTask(Task task, {bool isFirstPriority = false}) async {
    added.add(task);
  }

  @override
  void clearTaskInQueue(String taskId) =>
      added.removeWhere((task) => task.id == taskId);
}

class _FakeMediaApi extends Mock implements MediaAPI {
  @override
  Future<UploadFileResponse> uploadFileMobile({
    required FileInfo fileInfo,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async => const UploadFileResponse(contentUri: 'mxc://fakeServer/file');
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _ReplyAwareDatabase extends LenientDatabase {
  Event? replyTarget;

  @override
  Future<Event?> getEventById(String eventId, Room room) async =>
      eventId == replyTarget?.eventId ? replyTarget : null;
}

const _thread = ThreadSendTarget(rootEventId: r'$root', lastEventId: r'$last');

void main() {
  late Room room;
  late Event replyTarget;
  late _RecordingQueue queue;
  late UploadManager manager;
  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;

  setUpAll(() async {
    queue = _RecordingQueue();
    getIt.registerSingleton<UploadWorkerQueue>(queue);
    getIt.registerSingleton<MediaAPI>(_FakeMediaApi());
    tempDir = await Directory.systemTemp.createTemp('cancel_caption_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    final database = _ReplyAwareDatabase();
    final client = await getClient(database: database);
    room = Room(
      client: client,
      id: '!1234:fakeServer.notExisting',
      membership: Membership.join,
    );
    replyTarget = Event(
      senderId: '@bob:example.com',
      type: 'm.room.message',
      room: room,
      eventId: r'$target',
      content: {'msgtype': 'm.text', 'body': 'hi'},
      originServerTs: DateTime.utc(2026, 11, 9),
    );
    database.replyTarget = replyTarget;
    manager = UploadManager();
  });

  tearDownAll(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await tempDir.delete(recursive: true);
    await GetIt.I.reset();
  });

  setUp(() {
    queue.added.clear();
    FakeMatrixApi.calledEndpoints.clear();
  });

  List<Map<String, Object?>> sentMessages() => [
    for (final entry in FakeMatrixApi.calledEndpoints.entries)
      if (entry.key.contains('/send/m.room.message/'))
        for (final body in entry.value)
          (jsonDecode(body as String) as Map).cast<String, Object?>(),
  ];

  Future<void> runNextSend() async {
    final task = queue.added.removeAt(0);
    await task.runnable();
    task.onTaskCompleted?.call();
    await pumpEventQueue();
  }

  Future<void> runQueuedSends() async {
    while (queue.added.isNotEmpty) {
      await runNextSend();
    }
  }

  Future<List<String>> send(
    List<String> names, {
    String? caption = 'look',
    ThreadSendTarget? thread,
  }) async {
    await manager.uploadFileMobile(
      room: room,
      fileInfos: [
        for (final name in names)
          FileInfo(name, bytes: Uint8List.fromList([1, 2, 3])),
      ],
      caption: caption,
      inReplyTo: thread == null ? replyTarget : null,
      thread: thread,
    );
    return [for (final task in queue.added) task.id!];
  }

  Future<void> cancel(String txid) => manager.cancelUpload(
    Event(
      senderId: room.client.userID!,
      type: EventTypes.Message,
      room: room,
      eventId: txid,
      status: EventStatus.sending,
      content: {'msgtype': MessageTypes.File, 'body': ''},
      originServerTs: DateTime.now(),
    ),
  );

  bool hasCaption(Map<String, Object?> content) =>
      '${content['body']}'.endsWith('look');

  Object? replyOf(Map<String, Object?> content) =>
      (content['m.relates_to'] as Map?)?['m.in_reply_to'];

  const reply = {'event_id': r'$target'};

  test('cancelling the captioned file before it starts moves the caption to '
      'the last file still waiting', () async {
    final txids = await send(['a.txt', 'b.txt', 'c.txt']);

    await cancel(txids.last);
    await runQueuedSends();

    final sent = sentMessages();
    expect(sent, hasLength(2));
    expect(replyOf(sent[0]), reply);
    expect(hasCaption(sent[0]), isFalse);
    expect(hasCaption(sent[1]), isTrue);
  });

  test('cancelling the captioned file once the others are sent sends the '
      'caption as a text message', () async {
    final txids = await send(['a.txt', 'b.txt', 'c.txt']);
    await runNextSend();
    await runNextSend();

    await cancel(txids.last);
    await runQueuedSends();

    final sent = sentMessages();
    expect(sent, hasLength(3));
    expect(sent.last['msgtype'], MessageTypes.Text);
    expect(sent.last['body'], 'look');
    expect(replyOf(sent.last), isNull);
  });

  test('cancelling the first file moves the reply to the next one', () async {
    final txids = await send(['a.txt', 'b.txt', 'c.txt']);

    await cancel(txids.first);
    await runQueuedSends();

    final sent = sentMessages();
    expect(sent, hasLength(2));
    expect(replyOf(sent[0]), reply);
    expect(replyOf(sent[1]), isNull);
    expect(hasCaption(sent[1]), isTrue);
  });

  test('cancelling a file without caption nor reply changes nothing', () async {
    final txids = await send(['a.txt', 'b.txt', 'c.txt']);

    await cancel(txids[1]);
    await runQueuedSends();

    final sent = sentMessages();
    expect(sent, hasLength(2));
    expect(replyOf(sent[0]), reply);
    expect(hasCaption(sent[0]), isFalse);
    expect(replyOf(sent[1]), isNull);
    expect(hasCaption(sent[1]), isTrue);
  });

  test('cancelling a lone file keeps its caption and reply as a text '
      'message', () async {
    final txids = await send(['a.txt']);

    await cancel(txids.single);
    await runQueuedSends();

    final sent = sentMessages();
    expect(sent, hasLength(1));
    expect(sent.single['msgtype'], MessageTypes.Text);
    expect(replyOf(sent.single), reply);
    expect(hasCaption(sent.single), isTrue);
  });

  test('the caption sent as text stays in the thread', () async {
    final txids = await send(['a.txt'], thread: _thread);

    await cancel(txids.single);
    await runQueuedSends();

    final sent = sentMessages().single;
    expect(sent['body'], 'look');
    expect(sent['m.relates_to'], _thread.relatesTo);
  });

  test('cancelling a lone file without caption sends nothing', () async {
    final txids = await send(['a.txt'], caption: null);

    await cancel(txids.single);
    await runQueuedSends();

    expect(sentMessages(), isEmpty);
  });
}
