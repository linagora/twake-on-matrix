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
import 'package:twake_chat/domain/model/file_info/image_file_info.dart';
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

class _PickedHeicPhoto extends FileAssetEntity {
  _PickedHeicPhoto(this.path)
    : super(assetEntity: AssetEntity(id: '2', typeInt: 1, width: 4, height: 3));

  final String path;

  @override
  Future<FileInfo?> toFileInfo() async => ImageFileInfo(
    'photo.heic',
    filePath: path,
    customMimeType: 'image/heic',
    width: 4,
    height: 3,
  );

  @override
  String get messageType => MessageTypes.Image;
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
  final statusUpdates = <String, int?>{};

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
        statusUpdates[event.eventId] =
            event.unsigned?[messageSendingStatusKey] as int?;
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
    statusUpdates.clear();
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
  Event eventAfterRestart(
    String eventId, {
    EventStatus status = EventStatus.error,
  }) {
    final placeholder = placeholders.last;
    final event = Event(
      senderId: room.client.userID!,
      type: placeholder.type,
      room: room,
      eventId: eventId,
      content: placeholder.content,
      unsigned: {...?placeholder.unsigned, 'transaction_id': eventId},
      status: status,
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
      // The kill dropped the queued upload: only the retry may send.
      queue.added.clear();

      final result = await manager.retryUpload(
        eventAfterRestart('restarted-${entry.name}'),
      );
      await pumpEventQueue();

      expect(result, RetryUploadResult.started);
      expect(queue.added, hasLength(1));
      await runQueuedSends();
      expect(sentMessages(), isNotEmpty);
    });

    test('${entry.name}: an upload cut by a process kill shows as failed when '
        'its chat opens again, while a live one keeps sending', () async {
      await entry.upload();
      await pumpEventQueue();
      final live = placeholders.last;
      final liveEvent = Event.fromMatrixEvent(live, room);
      final interrupted = eventAfterRestart(
        'restarted-${entry.name}',
        status: EventStatus.sending,
      );
      final sent = eventAfterRestart(
        'sent-${entry.name}',
        status: EventStatus.sent,
      );
      final sendingText = Event(
        senderId: room.client.userID!,
        type: EventTypes.Message,
        room: room,
        eventId: 'text-${entry.name}',
        content: {'msgtype': MessageTypes.Text, 'body': 'hello'},
        status: EventStatus.sending,
        originServerTs: DateTime.now(),
      );
      statusUpdates.clear();

      await manager.failInterruptedUploads([
        liveEvent,
        interrupted,
        sent,
        sendingText,
      ]);
      await pumpEventQueue();

      expect(statusUpdates[interrupted.eventId], EventStatus.error.intValue);
      expect(statusUpdates, isNot(contains(live.eventId)));
      expect(statusUpdates, isNot(contains(sent.eventId)));
      expect(statusUpdates, isNot(contains(sendingText.eventId)));
    });
  }

  test('interrupted uploads all fail even when the timeline grows while they '
      'are marked', () async {
    await manager.uploadFileMobile(
      room: room,
      fileInfos: [FileInfo('notes.txt', filePath: pickedFile.path)],
    );
    await pumpEventQueue();
    final timeline = [
      eventAfterRestart('restarted-first', status: EventStatus.sending),
      eventAfterRestart('restarted-second', status: EventStatus.sending),
    ];
    final growTimeline = room.client.onSync.stream.listen((_) {
      if (timeline.length == 2) {
        timeline.add(
          eventAfterRestart('restarted-third', status: EventStatus.sent),
        );
      }
    });
    addTearDown(growTimeline.cancel);
    statusUpdates.clear();

    await manager.failInterruptedUploads(timeline);
    await pumpEventQueue();

    expect(statusUpdates['restarted-first'], EventStatus.error.intValue);
    expect(statusUpdates['restarted-second'], EventStatus.error.intValue);
  });

  test('a file the OS removed before the retry cannot be resent', () async {
    final removedFile = File('${tempDir.path}/removed.txt')
      ..writeAsBytesSync([1, 2, 3]);
    await manager.uploadFileMobile(
      room: room,
      fileInfos: [FileInfo('removed.txt', filePath: removedFile.path)],
    );
    await pumpEventQueue();
    queue.added.clear();
    removedFile.deleteSync();

    final result = await manager.retryUpload(
      eventAfterRestart('restarted-removed'),
    );

    expect(result, RetryUploadResult.fileDataUnavailable);
    expect(queue.added, isEmpty);
  });

  test('a HEIC photo restored after a process kill is still an image, so the '
      'retry converts it to JPG', () async {
    final photo = File('${tempDir.path}/photo.heic')..writeAsBytesSync([1, 2]);
    await manager.uploadMediaMobile(
      room: room,
      entities: [_PickedHeicPhoto(photo.path)],
    );
    await pumpEventQueue();
    queue.added.clear();

    final restored = await manager.getUploadFileInfo(
      eventAfterRestart('restarted-heic').eventId,
      room: room,
    );

    expect(restored?.fileInfo, isA<ImageFileInfo>());
    expect(restored?.fileInfo?.mimeType, 'image/heic');
  });
}
