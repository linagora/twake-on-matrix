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
import 'package:photo_manager/photo_manager.dart';
import 'package:twake_chat/data/model/media/upload_file_json.dart';
import 'package:twake_chat/data/network/media/media_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/presentation/model/file/file_asset_entity.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/manager/upload_manager/models/retry_upload_result.dart';
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
}

/// The media repository: answers every upload with a content uri, or fails
/// the next one when asked to.
class _FakeMediaApi extends Mock implements MediaAPI {
  bool failNextUpload = false;

  Future<UploadFileResponse> _answer() async {
    if (failNextUpload) {
      failNextUpload = false;
      throw Exception('network down');
    }
    return const UploadFileResponse(contentUri: 'mxc://fakeServer/file');
  }

  @override
  Future<UploadFileResponse> uploadFileWeb({
    required MatrixFile file,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) => _answer();

  @override
  Future<UploadFileResponse> uploadFileMobile({
    required FileInfo fileInfo,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) => _answer();
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

/// Knows the replied-to message, so a retry can find it again.
class _ReplyAwareDatabase extends LenientDatabase {
  Event? replyTarget;

  @override
  Future<Event?> getEventById(String eventId, Room room) async =>
      eventId == replyTarget?.eventId ? replyTarget : null;
}

/// A file picked from the gallery, without the platform photo library.
class _PickedFile extends FileAssetEntity {
  _PickedFile()
    : super(assetEntity: AssetEntity(id: '1', typeInt: 0, width: 0, height: 0));

  @override
  Future<FileInfo?> toFileInfo() async =>
      FileInfo('notes.txt', bytes: Uint8List.fromList([1, 2, 3]));

  @override
  String get messageType => MessageTypes.File;
}

const _thread = ThreadSendTarget(rootEventId: r'$root', lastEventId: r'$last');

void main() {
  late Room room;
  late Event replyTarget;
  late _RecordingQueue queue;
  late _FakeMediaApi mediaApi;
  late UploadManager manager;
  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;
  final placeholders = <MatrixEvent>[];

  setUpAll(() async {
    queue = _RecordingQueue();
    mediaApi = _FakeMediaApi();
    getIt.registerSingleton<UploadWorkerQueue>(queue);
    getIt.registerSingleton<MediaAPI>(mediaApi);
    tempDir = await Directory.systemTemp.createTemp('thread_reply_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    final database = _ReplyAwareDatabase();
    final client = await getClient(database: database);
    // FakeMatrixApi answers any send to this room.
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
        if (event.unsigned?['transaction_id'] == event.eventId) {
          placeholders.add(event);
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
    placeholders.clear();
    FakeMatrixApi.calledEndpoints.clear();
  });

  /// The content of every message the app sent to the server, in order.
  List<Map<String, Object?>> sentMessages() => [
    for (final entry in FakeMatrixApi.calledEndpoints.entries)
      if (entry.key.contains('/send/m.room.message/'))
        for (final body in entry.value)
          (jsonDecode(body as String) as Map).cast<String, Object?>(),
  ];

  Future<void> runQueuedSends() async {
    final tasks = [...queue.added];
    queue.added.clear();
    for (final task in tasks) {
      await task.runnable();
      task.onTaskCompleted?.call();
    }
  }

  MatrixFile textFile() =>
      MatrixFile(bytes: Uint8List.fromList([1, 2, 3]), name: 'notes.txt');

  FileInfo textFileInfo() =>
      FileInfo('notes.txt', bytes: Uint8List.fromList([1, 2, 3]));

  Future<void> uploadWeb(ThreadSendTarget? thread) => manager.uploadFilesWeb(
    room: room,
    files: [textFile()],
    caption: 'look',
    inReplyTo: replyTarget,
    thread: thread,
  );

  Future<void> uploadMobile(ThreadSendTarget? thread) =>
      manager.uploadFileMobile(
        room: room,
        fileInfos: [textFileInfo()],
        caption: 'look',
        inReplyTo: replyTarget,
        thread: thread,
      );

  Future<void> uploadGallery(ThreadSendTarget? thread) =>
      manager.uploadMediaMobile(
        room: room,
        entities: [_PickedFile()],
        caption: 'look',
        inReplyTo: replyTarget,
        thread: thread,
      );

  /// Sends a thread file whose first upload fails, then retries it.
  Future<void> failThenRetry(ThreadSendTarget? thread) async {
    mediaApi.failNextUpload = true;
    await uploadWeb(thread);
    final txid = queue.added.single.id!;
    await runQueuedSends();
    expect(sentMessages(), isEmpty, reason: 'the first upload failed');

    placeholders.clear();
    final result = await manager.retryUpload(
      Event(
        senderId: room.client.userID!,
        type: EventTypes.Message,
        room: room,
        eventId: txid,
        content: {'msgtype': MessageTypes.File, 'body': 'look'},
        originServerTs: DateTime.now(),
      ),
    );
    expect(result, RetryUploadResult.started);
    await pumpEventQueue();
  }

  /// Every way the app sends a file, as the user reaches it.
  final entryPoints =
      <({String name, Future<void> Function(ThreadSendTarget? thread) upload})>[
        (name: 'web', upload: uploadWeb),
        (name: 'mobile', upload: uploadMobile),
        (name: 'gallery', upload: uploadGallery),
      ];
  final threadEntryPoints = [
    ...entryPoints,
    (name: 'retry', upload: failThenRetry),
  ];

  void expectThreadMessageWithoutQuote(Map<String, Object?> content) {
    expect(content['body'], 'look', reason: 'no quote fallback in the body');
    expect(
      '${content['formatted_body'] ?? ''}',
      isNot(contains('<mx-reply>')),
      reason: 'no quote fallback in the formatted body',
    );
    expect(content['m.relates_to'], {
      'rel_type': 'm.thread',
      'event_id': r'$root',
      'is_falling_back': true,
      'm.in_reply_to': {'event_id': r'$last'},
    });
  }

  group('a file sent to a thread never quotes the message it replies to', () {
    for (final entry in threadEntryPoints) {
      test('${entry.name}: the message sent to the server has the thread '
          'relation and no quote', () async {
        await entry.upload(_thread);
        await runQueuedSends();

        final sent = sentMessages();
        expect(sent, isNotEmpty, reason: 'the file message reached the server');
        expectThreadMessageWithoutQuote(sent.single);
      });

      test('${entry.name}: the placeholder shown while uploading has no '
          'reply', () async {
        await entry.upload(_thread);
        await pumpEventQueue();

        expect(placeholders, isNotEmpty);
        for (final placeholder in placeholders) {
          expect(placeholder.unsigned, isNot(contains('in_reply_to')));
          expect(placeholder.content['m.relates_to'], _thread.relatesTo);
        }
      });
    }
  });

  group('a file sent outside a thread keeps its reply', () {
    for (final entry in entryPoints) {
      test(entry.name, () async {
        await entry.upload(null);
        await pumpEventQueue();
        expect(placeholders.first.unsigned?['in_reply_to'], r'$target');
        await runQueuedSends();

        final content = sentMessages().single;
        expect(content['m.relates_to'], {
          'm.in_reply_to': {'event_id': r'$target'},
        });
        expect(content['body'], startsWith('> <@bob:example.com> hi'));
      });
    }
  });
}
