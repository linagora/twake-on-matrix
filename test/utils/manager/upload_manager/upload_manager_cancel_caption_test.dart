// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
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
import 'package:twake_chat/domain/model/file_info/pending_file_info.dart';
import 'package:twake_chat/utils/manager/upload_manager/models/upload_caption_info.dart';
import 'package:twake_chat/utils/manager/upload_manager/models/upload_file_info.dart';
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
  bool failNextUpload = false;

  @override
  Future<UploadFileResponse> uploadFileMobile({
    required FileInfo fileInfo,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    if (failNextUpload) {
      failNextUpload = false;
      throw MatrixException.fromJson({
        'errcode': 'M_UNKNOWN',
        'error': 'network down',
      });
    }
    return const UploadFileResponse(contentUri: 'mxc://fakeServer/file');
  }
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

/// Knows the replied-to message and the placeholders shown so far; the
/// lookup of the replied-to message waits on [replyLookup] when it is set.
class _ReplyAwareDatabase extends LenientDatabase {
  Event? replyTarget;
  Completer<void>? replyLookup;
  bool replyLookupFails = false;
  final Map<String, Event> stored = {};

  @override
  Future<Event?> getEventById(String eventId, Room room) async {
    if (eventId != replyTarget?.eventId) return stored[eventId];
    await replyLookup?.future;
    if (replyLookupFails) throw Exception('offline');
    return replyTarget;
  }
}

const _thread = ThreadSendTarget(rootEventId: r'$root', lastEventId: r'$last');

void main() {
  late Room room;
  late Event replyTarget;
  late _RecordingQueue queue;
  late UploadManager manager;
  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;
  late _ReplyAwareDatabase database;
  late _FakeMediaApi mediaApi;
  final savedUploadInfo = <String, Map<String, dynamic>>{};

  setUpAll(() async {
    queue = _RecordingQueue();
    getIt.registerSingleton<UploadWorkerQueue>(queue);
    mediaApi = _FakeMediaApi();
    getIt.registerSingleton<MediaAPI>(mediaApi);
    tempDir = await Directory.systemTemp.createTemp('cancel_caption_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    database = _ReplyAwareDatabase();
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
    client.onSync.stream.listen((update) {
      for (final event
          in update.rooms?.join?[room.id]?.timeline?.events ??
              const <MatrixEvent>[]) {
        if (event.unsigned?['transaction_id'] != event.eventId) continue;
        database.stored[event.eventId] = Event.fromMatrixEvent(event, room);
        final uploadInfo = event.unsigned?['upload_info'];
        if (uploadInfo is Map<String, dynamic>) {
          savedUploadInfo[event.eventId] = uploadInfo;
        }
      }
    });
    manager = UploadManager();
  });

  tearDownAll(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await tempDir.delete(recursive: true);
    await GetIt.I.reset();
  });

  setUp(() {
    queue.added.clear();
    database
      ..replyLookup = null
      ..replyLookupFails = false;
    mediaApi.failNextUpload = false;
    savedUploadInfo.clear();
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

  /// A file of a batch as the app finds it in its database after a restart.
  Event restored(String txid, {UploadCaptionInfo? caption, String? reply}) {
    final file = File('${tempDir.path}/$txid.txt')..writeAsBytesSync([1, 2, 3]);
    final info = UploadFileInfo(
      txid: txid,
      createdAt: DateTime.now(),
      uploadStateStreamController: StreamController(),
      cancelToken: CancelToken(),
      captionInfo: caption,
      inReplyToEventId: reply,
      batchId: 'restored-batch',
      fileInfo: FileInfo('$txid.txt', filePath: file.path),
    );
    return database.stored[txid] = Event(
      senderId: room.client.userID!,
      type: EventTypes.Message,
      room: room,
      eventId: txid,
      status: EventStatus.error,
      content: {'msgtype': MessageTypes.File, 'body': 'restored.txt'},
      unsigned: {'transaction_id': txid, 'upload_info': info.toJson()},
      originServerTs: DateTime.now(),
    );
  }

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

  test('the caption handed over is saved in the placeholder for a retry '
      'after a restart', () async {
    final txids = await send(['a.txt', 'b.txt', 'c.txt']);

    await cancel(txids.last);
    await pumpEventQueue();

    final saved = savedUploadInfo[txids[1]];
    expect((saved?['captionInfo'] as Map?)?['caption'], 'look');
  });

  test('a file whose bytes never came does not take the caption', () async {
    await manager.uploadFileMobile(
      room: room,
      fileInfos: [
        PendingFileInfo(
          'a.txt',
          size: 3,
          resolved: Future<FileInfo>.error(Exception('download failed')),
        ),
        FileInfo('b.txt', bytes: Uint8List.fromList([1, 2, 3])),
      ],
      caption: 'look',
      inReplyTo: replyTarget,
    );
    await pumpEventQueue();

    await cancel(queue.added.single.id!);
    await runQueuedSends();

    final sent = sentMessages().single;
    expect(sent['msgtype'], MessageTypes.Text);
    expect(sent['body'], 'look');
  });

  test('a file that starts while the reply is looked up does not take the '
      'caption nor the reply', () async {
    // Both files of the batch come back from the database after a restart.
    final first = restored(
      'restored-1',
      caption: UploadCaptionInfo(txid: 'restored-caption', caption: 'look'),
      reply: replyTarget.eventId,
    );
    final second = restored('restored-2');
    await manager.getUploadFileInfo(first.eventId, room: room);
    await manager.retryUpload(second);

    database.replyLookup = Completer();
    final cancelling = manager.cancelUpload(first);
    final secondSend = queue.added.removeAt(0);
    final sending = secondSend.runnable();
    database.replyLookup!.complete();
    await cancelling;
    await sending;
    secondSend.onTaskCompleted?.call();
    await runQueuedSends();

    final sent = sentMessages();
    expect(sent, hasLength(2));
    expect(replyOf(sent.first), isNull);
    expect(sent.last['msgtype'], MessageTypes.Text);
    expect(hasCaption(sent.last), isTrue);
    expect(replyOf(sent.last), reply);
  });
  test('a reply that cannot be looked up is dropped and the caption still '
      'goes as a text message', () async {
    final lone = restored(
      'restored-offline',
      caption: UploadCaptionInfo(txid: 'offline-caption', caption: 'look'),
      reply: replyTarget.eventId,
    );
    await manager.getUploadFileInfo(lone.eventId, room: room);
    database.replyLookupFails = true;

    await manager.cancelUpload(lone);
    await runQueuedSends();

    final sent = sentMessages().single;
    expect(sent['msgtype'], MessageTypes.Text);
    expect(sent['body'], 'look');
    expect(replyOf(sent), isNull);
  });

  test('retrying the file that took the caption sends the caption', () async {
    final txids = await send(['a.txt', 'b.txt', 'c.txt']);
    await cancel(txids.last);
    await runNextSend();
    mediaApi.failNextUpload = true;
    await runNextSend();
    expect(sentMessages(), hasLength(1), reason: 'the second upload failed');

    await manager.retryUpload(
      Event(
        senderId: room.client.userID!,
        type: EventTypes.Message,
        room: room,
        eventId: txids[1],
        status: EventStatus.error,
        content: {'msgtype': MessageTypes.File, 'body': 'b.txt'},
        originServerTs: DateTime.now(),
      ),
    );
    await runQueuedSends();

    final sent = sentMessages();
    expect(sent, hasLength(2));
    expect(hasCaption(sent.last), isTrue);
  });
  test('a cancelled send that fails keeps no caption to send again', () async {
    final txid = (await send(['a.txt'])).single;
    final upload = queue.added.removeAt(0);
    mediaApi.failNextUpload = true;
    // The failure then reports to the stream the cancel already closed.
    final running = upload.runnable().then((_) {}, onError: (_) {});

    await cancel(txid);
    await running;
    await pumpEventQueue();
    await runQueuedSends();

    expect(savedUploadInfo[txid]?['captionInfo'], isNull);
    expect(savedUploadInfo[txid]?['inReplyToEventId'], isNull);
    expect(sentMessages().single['body'], endsWith('look'));
  });
}
