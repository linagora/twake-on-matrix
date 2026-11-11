import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_worker_queue.dart';
import 'package:twake_chat/utils/task_queue/task.dart';

import '../../../lenient_database.dart';

/// Records the queued tasks and never runs them, so no upload starts.
class _RecordingQueue extends UploadWorkerQueue {
  final List<Task> added = [];

  @override
  Future addTask(Task task, {bool isFirstPriority = false}) async {
    added.add(task);
  }
}

void main() {
  late Room room;
  late Event replyTarget;
  late _RecordingQueue queue;
  late UploadManager manager;

  FileInfo image(String name) =>
      FileInfo(name, bytes: Uint8List.fromList([1, 2, 3]));

  setUpAll(() async {
    queue = _RecordingQueue();
    if (getIt.isRegistered<UploadWorkerQueue>()) {
      getIt.unregister<UploadWorkerQueue>();
    }
    getIt.registerSingleton<UploadWorkerQueue>(queue);
    room = await getLenientRoom('!album:example.com');
    replyTarget = Event(
      senderId: '@bob:example.com',
      type: 'm.room.message',
      room: room,
      eventId: r'$target',
      content: {'body': 'hi'},
      originServerTs: DateTime.utc(2026, 11, 9),
    );
    manager = UploadManager();
  });

  tearDownAll(() => GetIt.I.reset());

  Future<List<UploadInfoView>> send(
    List<FileInfo> files, {
    String? caption,
    Event? inReplyTo,
  }) async {
    queue.added.clear();
    await manager.uploadFileMobile(
      room: room,
      fileInfos: files,
      caption: caption,
      inReplyTo: inReplyTo,
    );
    return [
      for (final task in queue.added)
        UploadInfoView(
          (await manager.getUploadFileInfo(task.id!, room: room))!,
        ),
    ];
  }

  test('the web send path stamps, replies and captions the same way', () async {
    queue.added.clear();
    await manager.uploadFilesWeb(
      room: room,
      files: [
        for (final name in ['a.png', 'b.png', 'c.png'])
          MatrixFile(bytes: Uint8List.fromList([1, 2, 3]), name: name),
      ],
      caption: 'hello',
      inReplyTo: replyTarget,
    );
    final infos = [
      for (final task in queue.added)
        UploadInfoView(
          (await manager.getUploadFileInfo(task.id!, room: room))!,
        ),
    ];

    expect(infos, hasLength(3));
    expect(infos.map((i) => i.batchId).toSet(), hasLength(1));
    expect(infos.first.batchId, isNotNull);
    expect(infos.map((i) => i.replyTo), [r'$target', null, null]);
    expect(infos.map((i) => i.caption), [null, null, 'hello']);
  });

  test('every file of a send shares one batch id', () async {
    final infos = await send([image('a.png'), image('b.png'), image('c.png')]);

    expect(infos, hasLength(3));
    expect(infos.map((i) => i.batchId).toSet(), hasLength(1));
    expect(infos.first.batchId, isNotNull);
    expect(infos.first.batchId, isNot(infos.first.txid));
  });

  test('a single file carries no batch id', () async {
    final infos = await send([image('a.png')]);

    expect(infos.single.batchId, isNull);
  });

  test('two sends get two different batch ids', () async {
    final first = await send([image('a.png'), image('b.png')]);
    final second = await send([image('a.png'), image('b.png')]);

    expect(first.first.batchId, isNot(second.first.batchId));
  });

  test(
    'the reply goes on the first file and the caption on the last',
    () async {
      final infos = await send(
        [image('a.png'), image('b.png'), image('c.png')],
        caption: 'hello',
        inReplyTo: replyTarget,
      );

      expect(infos.map((i) => i.replyTo), [r'$target', null, null]);
      expect(infos.map((i) => i.caption), [null, null, 'hello']);
    },
  );
}

class UploadInfoView {
  final dynamic _info;

  UploadInfoView(this._info);

  String get txid => _info.txid as String;
  String? get batchId => _info.batchId as String?;
  String? get replyTo => _info.inReplyToEventId as String?;
  String? get caption => _info.captionInfo?.caption as String?;
}
