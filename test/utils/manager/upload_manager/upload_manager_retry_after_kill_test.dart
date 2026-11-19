// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

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
import 'package:twake_chat/utils/manager/upload_manager/models/retry_upload_result.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_worker_queue.dart';
import 'package:twake_chat/utils/task_queue/task.dart';

import '../../../fake_client.dart';
import '../../../lenient_database.dart';

class _RecordingQueue extends UploadWorkerQueue {
  final List<Task> added = [];

  @override
  Future addTask(Task task, {bool isFirstPriority = false}) async {
    added.add(task);
  }
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

/// The events the app stored before it was killed.
class _StoredEventsDatabase extends LenientDatabase {
  final Map<String, Event> events = {};

  @override
  Future<Event?> getEventById(String eventId, Room room) async =>
      events[eventId];
}

class _PickedFile extends FileAssetEntity {
  _PickedFile(this.path)
    : super(assetEntity: AssetEntity(id: '1', typeInt: 0, width: 0, height: 0));

  final String path;

  @override
  Future<FileInfo?> toFileInfo() async => FileInfo('notes.txt', filePath: path);

  @override
  String get messageType => MessageTypes.File;
}

void main() {
  late Room room;
  late _RecordingQueue queue;
  late _StoredEventsDatabase database;
  late UploadManager manager;
  late Directory tempDir;
  late File pickedFile;
  late PathProviderPlatform originalPathProvider;
  final placeholders = <MatrixEvent>[];

  setUpAll(() async {
    queue = _RecordingQueue();
    getIt.registerSingleton<UploadWorkerQueue>(queue);
    getIt.registerSingleton<MediaAPI>(_FakeMediaApi());
    tempDir = await Directory.systemTemp.createTemp('retry_after_kill_test');
    pickedFile = File('${tempDir.path}/notes.txt')..writeAsBytesSync([1, 2, 3]);
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    database = _StoredEventsDatabase();
    final client = await getClient(database: database);
    room = Room(
      client: client,
      id: '!1234:fakeServer.notExisting',
      membership: Membership.join,
    );
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
    database.events.clear();
    FakeMatrixApi.calledEndpoints.clear();
  });

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

  /// The local event as the app finds it in its database after a restart:
  /// the placeholder written before the upload began, which never finished.
  Event eventAfterRestart(String eventId) {
    final placeholder = placeholders.last;
    final event = Event(
      senderId: room.client.userID!,
      type: placeholder.type,
      room: room,
      eventId: eventId,
      content: placeholder.content,
      unsigned: {...?placeholder.unsigned, 'transaction_id': eventId},
      status: EventStatus.error,
      originServerTs: DateTime.now(),
    );
    database.events[eventId] = event;
    return event;
  }

  final entryPoints = <({String name, Future<void> Function() upload})>[
    (
      name: 'mobile',
      upload: () => manager.uploadFileMobile(
        room: room,
        fileInfos: [FileInfo('notes.txt', filePath: pickedFile.path)],
      ),
    ),
    (
      name: 'gallery',
      upload: () => manager.uploadMediaMobile(
        room: room,
        entities: [_PickedFile(pickedFile.path)],
      ),
    ),
  ];

  for (final entry in entryPoints) {
    test('${entry.name}: a file whose upload was cut by a process kill is '
        'sent again on retry', () async {
      await entry.upload();
      await pumpEventQueue();
      expect(placeholders, isNotEmpty);

      final result = await manager.retryUpload(
        eventAfterRestart('restarted-${entry.name}'),
      );
      await pumpEventQueue();
      await runQueuedSends();

      expect(result, RetryUploadResult.started);
      expect(sentMessages(), isNotEmpty);
    });
  }
}
