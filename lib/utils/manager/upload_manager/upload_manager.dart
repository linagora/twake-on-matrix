import 'dart:async';
import 'package:dartz/dartz.dart' hide Task;
import 'package:dio/dio.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/network/extensions/file_info_extension.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/domain/model/file_info/pending_file_info.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/presentation/extensions/send_file_extension.dart';
import 'package:twake_chat/presentation/extensions/send_file_fake_event_extension.dart';
import 'package:twake_chat/presentation/extensions/send_file_web_extension.dart';
import 'package:twake_chat/presentation/model/file/file_asset_entity.dart';
import 'package:twake_chat/utils/manager/upload_manager/models/retry_upload_result.dart';
import 'package:twake_chat/utils/manager/upload_manager/models/upload_caption_info.dart';
import 'package:twake_chat/utils/manager/upload_manager/models/upload_file_info.dart';
import 'package:twake_chat/utils/manager/upload_manager/pending_upload_order.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_state.dart';
import 'package:twake_chat/domain/media_album/policy/media_batch_stamp.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_worker_queue.dart';
import 'package:twake_chat/utils/task_queue/task.dart';
import 'package:matrix/matrix.dart';
import 'package:rxdart/rxdart.dart';

class UploadManager {
  final MediaBatchStamp _batchStamp = const MediaBatchStamp();

  UploadManager._();

  static final UploadManager _instance = UploadManager._();

  factory UploadManager() => _instance;

  final uploadWorkerQueue = getIt.get<UploadWorkerQueue>();

  static final Map<String, UploadFileInfo> _eventIdMapUploadFileInfo = {};

  final Set<String> _retriesInProgress = {};

  static const int _shrinkImageMaxDimension = 1600;

  Future<UploadFileInfo?> getUploadFileInfo(
    String eventId, {
    required Room room,
  }) async {
    final cached = _eventIdMapUploadFileInfo[eventId];
    if (cached != null &&
        (cached.fileInfo != null || cached.matrixFile != null)) {
      return cached;
    }

    // Attempt to restore on-demand from the event's unsigned data.
    // Only cache the restored entry when it has usable file data — otherwise
    // a null-byte entry would poison the map and mask the data-lost condition.
    final event = await room.getEventById(eventId);
    if (event != null) {
      final uploadInfoMap = event.unsigned?['upload_info'];
      if (uploadInfoMap is Map<String, dynamic>) {
        try {
          final info = UploadFileInfo.fromJson(uploadInfoMap);
          if (info.fileInfo != null || info.matrixFile != null) {
            _eventIdMapUploadFileInfo[eventId] = info;
          }
          return info;
        } catch (e) {
          Logs().w(
            'UploadManager::getUploadFileInfo(): '
            'failed to parse upload_info for $eventId, ignoring: $e',
          );
        }
      }
    }

    return null;
  }

  Future<void> cancelUpload(Event event) async {
    final cancelToken = _eventIdMapUploadFileInfo[event.eventId]?.cancelToken;
    if (cancelToken != null) {
      Logs().d('Remove eventid: ${event.eventId}');
      event.room.sendingFilePlaceholders.remove(event.eventId);
      _clearFileTask(event.eventId);
      event.remove();
      cancelToken.cancel();
    }
  }

  Future<MatrixFile?> getMatrixFile(
    String eventId, {
    required Room room,
  }) async {
    try {
      final uploadInfo = await getUploadFileInfo(eventId, room: room);
      if (uploadInfo == null) {
        return null;
      }
      final fileInfo = uploadInfo.fileInfo;
      // A pending file has no bytes to show yet, and reading a saved one into
      // memory on every rebuild of the timeline would cost more than it shows.
      if (fileInfo is PendingFileInfo) return null;
      return uploadInfo.matrixFile ?? await fileInfo?.toMatrixFile();
    } catch (e) {
      Logs().e('Error getting matrix file for eventid $eventId', e);
      return null;
    }
  }

  /// Retries a failed upload
  Future<RetryUploadResult> retryUpload(Event event) async {
    final txid = event.eventId;
    if (_retriesInProgress.contains(txid)) {
      Logs().w('Retry already in progress for txid $txid');
      return RetryUploadResult.alreadyInProgress;
    }
    _retriesInProgress.add(txid);
    try {
      final uploadInfo = await getUploadFileInfo(txid, room: event.room);

      if (uploadInfo == null) {
        Logs().w(
          'UploadManager::retryUpload(): no upload info for $txid, '
          'the message cannot be resent',
        );
        return RetryUploadResult.fileDataUnavailable;
      }

      final room = event.room;
      final fileInfo = uploadInfo.fileInfo;
      final matrixFile = uploadInfo.matrixFile;

      // File bytes lost (e.g. web page refresh): keep the event in the timeline
      // and let the caller tell the user, rather than silently dropping it.
      if (fileInfo == null && matrixFile == null) {
        Logs().w(
          'UploadManager::retryUpload(): no file data for $txid, '
          'the message cannot be resent',
        );
        return RetryUploadResult.fileDataUnavailable;
      }

      if (!uploadInfo.isFailed) {
        Logs().w('UploadManager::retryUpload(): $txid is not in failed state');
        await event.cancelSend();
        return RetryUploadResult.notFailed;
      }

      final caption = uploadInfo.captionInfo?.caption;
      final inReplyTo = uploadInfo.inReplyToEventId == null
          ? null
          : await room.getEventById(uploadInfo.inReplyToEventId!);
      uploadInfo.isFailed = false;
      SyncUpdate? fakeImageEvent;
      try {
        if (fileInfo != null) {
          fakeImageEvent = await room.sendFakeFileInfoEvent(
            fileInfo,
            txid: txid,
            messageType: event.messageType,
            captionInfo: caption,
            uploadInfo: uploadInfo.toJson(),
            inReplyTo: inReplyTo,
            extraContent: _batchStamp.contentFor(uploadInfo.batchId),
          );
        } else {
          fakeImageEvent = await room.sendFakeFileEvent(
            matrixFile!,
            txid: txid,
            captionInfo: caption,
            uploadInfo: uploadInfo.toJson(),
            inReplyTo: inReplyTo,
            extraContent: _batchStamp.contentFor(uploadInfo.batchId),
          );
        }
      } catch (e) {
        uploadInfo.isFailed = true;
        rethrow;
      }

      final streamController = uploadInfo.uploadStateStreamController;
      final cancelToken = uploadInfo.cancelToken;

      streamController.add(const Right(UploadFileInitial()));

      try {
        if (fileInfo != null) {
          _addFileTaskToWorkerQueueMobile(
            txid: txid,
            fakeImageEvent: fakeImageEvent,
            room: room,
            fileInfo: fileInfo,
            streamController: streamController,
            cancelToken: cancelToken,
            sentDate: uploadInfo.createdAt,
            shrinkImageMaxDimension: uploadInfo.shrinkImageMaxDimension,
            captionInfo: caption,
            uploadInfo: uploadInfo.toJson(),
            inReplyTo: inReplyTo,
          );
        } else {
          await _addFileTaskToWorkerQueueWeb(
            txid: txid,
            fakeImageEvent: fakeImageEvent,
            room: room,
            matrixFile: matrixFile!,
            streamController: streamController,
            cancelToken: cancelToken,
            thumbnail: uploadInfo.thumbnail,
            sentDate: uploadInfo.createdAt,
            captionInfo: caption,
            uploadInfo: uploadInfo.toJson(),
            inReplyTo: inReplyTo,
          );
        }
      } catch (e) {
        uploadInfo.isFailed = true;
        streamController.add(
          Left(
            UploadFileFailedState(
              exception: e is Exception ? e : Exception(e.toString()),
              txid: txid,
            ),
          ),
        );
        rethrow;
      }

      return RetryUploadResult.started;
    } finally {
      _retriesInProgress.remove(txid);
    }
  }

  Future<void> _clearFileTask(String eventId) async {
    try {
      uploadWorkerQueue.clearTaskInQueue(eventId);
      await _eventIdMapUploadFileInfo[eventId]?.uploadStateStreamController
          .close();
    } catch (e) {
      Logs().e('UploadManager::_clear(): Error $e');
    } finally {
      _eventIdMapUploadFileInfo.remove(eventId);
      Logs().i('UploadManager:: Clear with $eventId successfully');
    }
  }

  void _initUploadFileInfo({
    required String txid,
    required Room room,
    String? captionInfo,
    Event? inReplyTo,
    String? batchId,
  }) {
    final uploadController = BehaviorSubject<Either<Failure, Success>>();

    _eventIdMapUploadFileInfo[txid] = UploadFileInfo(
      txid: txid,
      uploadStateStreamController: uploadController,
      cancelToken: CancelToken(),
      createdAt: DateTime.now(),
      captionInfo: captionInfo != null && captionInfo.isNotEmpty
          ? UploadCaptionInfo(
              txid: room.client.generateUniqueTransactionId(),
              caption: captionInfo,
            )
          : null,
      inReplyToEventId: inReplyTo?.eventId,
      batchId: batchId,
    );
  }

  Map<String, Object>? _batchContentOf(String txid) =>
      _batchStamp.contentFor(_eventIdMapUploadFileInfo[txid]?.batchId);

  Stream<Either<Failure, Success>>? getUploadStateStream(String txid) {
    return _eventIdMapUploadFileInfo[txid]?.uploadStateStreamController.stream;
  }

  Future<void> uploadMediaMobile({
    required Room room,
    required List<FileAssetEntity> entities,
    String? caption,
    Event? inReplyTo,
  }) async {
    final txids = await room.sendPlaceholdersForImagePickerFiles(
      entities: entities,
      captionInfo: caption,
      inReplyTo: inReplyTo,
    );

    final batchId = _batchStamp.newBatchIdFor(txids.length);

    for (final txid in txids.entries) {
      final txidKey = txid.key;
      final fakeSendingFileInfo = txids[txidKey];
      if (fakeSendingFileInfo == null) {
        continue;
      }

      Logs().d('UploadManager::uploadMediaMobile(): txid: $txidKey');

      final isFirstFile = txidKey == txids.keys.first;
      final isLastFile = txidKey == txids.keys.last;

      _initUploadFileInfo(
        txid: txidKey,
        room: room,
        captionInfo: isLastFile ? caption : null,
        inReplyTo: isFirstFile ? inReplyTo : null,
        batchId: batchId,
      );

      final sentDate = _eventIdMapUploadFileInfo[txidKey]?.createdAt;

      final fakeImageEvent = await room.sendFakeFileInfoEvent(
        fakeSendingFileInfo.fileInfo,
        txid: txidKey,
        messageType: fakeSendingFileInfo.messageType,
        sentDate: sentDate,
        captionInfo: _eventIdMapUploadFileInfo[txidKey]?.captionInfo?.caption,
        inReplyTo: isFirstFile ? inReplyTo : null,
        extraContent: _batchContentOf(txidKey),
        uploadInfo: _eventIdMapUploadFileInfo[txidKey]?.toJson(),
      );

      final streamController =
          _eventIdMapUploadFileInfo[txidKey]?.uploadStateStreamController;

      final cancelToken = _eventIdMapUploadFileInfo[txidKey]?.cancelToken;

      if (streamController == null || cancelToken == null) {
        Logs().e(
          'DownloadManager::download(): streamController or cancelToken is null',
        );
        _eventIdMapUploadFileInfo[txidKey]?.uploadStateStreamController.add(
          Left(
            UploadFileFailedState(
              exception: Exception('streamController or cancelToken is null'),
              txid: txidKey,
            ),
          ),
        );
        return;
      }

      streamController.add(const Right(UploadFileInitial()));

      _addFileTaskToWorkerQueueMobile(
        txid: txidKey,
        fakeImageEvent: fakeImageEvent,
        room: room,
        fileInfo: fakeSendingFileInfo.fileInfo,
        streamController: streamController,
        cancelToken: cancelToken,
        sentDate: sentDate,
        shrinkImageMaxDimension: _shrinkImageMaxDimension,
        captionInfo: _eventIdMapUploadFileInfo[txidKey]?.captionInfo?.caption,
        inReplyTo: isFirstFile ? inReplyTo : null,
        uploadInfo: _eventIdMapUploadFileInfo[txidKey]?.toJson(),
      );
    }
  }

  Future<void> uploadFilesWeb({
    required Room room,
    required List<MatrixFile> files,
    Map<MatrixFile, MatrixImageFile?>? thumbnails,
    String? caption,
    Event? inReplyTo,
  }) async {
    // Store txids and fake events for all files
    final uploadTasks = <String, SyncUpdate>{};

    final batchId = _batchStamp.newBatchIdFor(files.length);

    // First pass: Create all placeholders and fake events
    for (final matrixFile in files.asMap().entries) {
      final txid = room.client.generateUniqueTransactionId();
      final fileIndex = matrixFile.key;
      final fileInfo = matrixFile.value;

      final isFirstFile = fileIndex == 0;
      final isLastFile = fileIndex == files.length - 1;

      _initUploadFileInfo(
        txid: txid,
        room: room,
        captionInfo: isLastFile ? caption : null,
        inReplyTo: isFirstFile ? inReplyTo : null,
        batchId: batchId,
      );

      room.sendingFilePlaceholders[txid] = fileInfo;
      final fakeFileEvent = await room.sendFakeFileEvent(
        fileInfo,
        txid: txid,
        captionInfo: _eventIdMapUploadFileInfo[txid]?.captionInfo?.caption,
        inReplyTo: isFirstFile ? inReplyTo : null,
        extraContent: _batchContentOf(txid),
        uploadInfo: _eventIdMapUploadFileInfo[txid]?.toJson(),
      );

      uploadTasks[txid] = fakeFileEvent;

      final streamController =
          _eventIdMapUploadFileInfo[txid]?.uploadStateStreamController;

      if (streamController != null) {
        streamController.add(const Right(UploadFileInitial()));
      }
    }

    // Second pass: Add all files to upload queue (uploads one by one)
    for (final matrixFile in files.asMap().entries) {
      final fileIndex = matrixFile.key;
      final fileInfo = matrixFile.value;
      final txid = uploadTasks.keys.elementAt(fileIndex);
      final fakeFileEvent = uploadTasks[txid]!;

      final isFirstFile = fileIndex == 0;

      final streamController =
          _eventIdMapUploadFileInfo[txid]?.uploadStateStreamController;

      final cancelToken = _eventIdMapUploadFileInfo[txid]?.cancelToken;

      final sentDate = _eventIdMapUploadFileInfo[txid]?.createdAt;

      if (streamController == null || cancelToken == null) {
        Logs().e(
          'DownloadManager::download(): streamController or cancelToken is null',
        );
        _eventIdMapUploadFileInfo[txid]?.uploadStateStreamController.add(
          Left(
            UploadFileFailedState(
              exception: Exception('streamController or cancelToken is null'),
              txid: txid,
            ),
          ),
        );
        continue;
      }

      _addFileTaskToWorkerQueueWeb(
        txid: txid,
        fakeImageEvent: fakeFileEvent,
        room: room,
        matrixFile: fileInfo,
        streamController: streamController,
        cancelToken: cancelToken,
        thumbnail: thumbnails?[fileInfo],
        sentDate: sentDate,
        captionInfo: _eventIdMapUploadFileInfo[txid]?.captionInfo?.caption,
        inReplyTo: isFirstFile ? inReplyTo : null,
        uploadInfo: _eventIdMapUploadFileInfo[txid]?.toJson(),
      );
    }
  }

  Future<void> uploadFileMobile({
    required Room room,
    required List<FileInfo> fileInfos,
    String? caption,
    Event? inReplyTo,
  }) async {
    final batchId = _batchStamp.newBatchIdFor(fileInfos.length);

    for (final fileInfo in fileInfos.asMap().entries) {
      final fileIndex = fileInfo.key;
      final fileValue = fileInfo.value;

      // A file still on its way has no bytes to keep as a placeholder yet.
      final txid = fileValue is PendingFileInfo
          ? room.client.generateUniqueTransactionId()
          : await room.storePlaceholderFileInMem(fileInfo: fileValue);

      Logs().d('UploadManager::uploadFileMobile(): txid: $txid');

      final isFirstFile = fileIndex == 0;
      final isLastFile = fileIndex == fileInfos.length - 1;

      _initUploadFileInfo(
        txid: txid,
        room: room,
        captionInfo: isLastFile ? caption : null,
        inReplyTo: isFirstFile ? inReplyTo : null,
        batchId: batchId,
      );

      final sentDate = _eventIdMapUploadFileInfo[txid]?.createdAt;

      final fakeEvent = await room.sendFakeFileInfoEvent(
        fileValue,
        txid: txid,
        messageType: fileValue.msgType,
        sentDate: sentDate,
        captionInfo: _eventIdMapUploadFileInfo[txid]?.captionInfo?.caption,
        inReplyTo: isFirstFile ? inReplyTo : null,
        extraContent: _batchContentOf(txid),
        uploadInfo: _eventIdMapUploadFileInfo[txid]?.toJson(),
      );

      final streamController =
          _eventIdMapUploadFileInfo[txid]?.uploadStateStreamController;

      final cancelToken = _eventIdMapUploadFileInfo[txid]?.cancelToken;

      if (streamController == null || cancelToken == null) {
        Logs().e(
          'DownloadManager::download(): streamController or cancelToken is null',
        );
        _eventIdMapUploadFileInfo[txid]?.uploadStateStreamController.add(
          Left(
            UploadFileFailedState(
              exception: Exception('streamController or cancelToken is null'),
              txid: txid,
            ),
          ),
        );
        return;
      }

      streamController.add(const Right(UploadFileInitial()));

      _addFileTaskToWorkerQueueMobile(
        txid: txid,
        fakeImageEvent: fakeEvent,
        room: room,
        fileInfo: fileValue,
        streamController: streamController,
        cancelToken: cancelToken,
        sentDate: sentDate,
        captionInfo: _eventIdMapUploadFileInfo[txid]?.captionInfo?.caption,
        inReplyTo: isFirstFile ? inReplyTo : null,
        uploadInfo: _eventIdMapUploadFileInfo[txid]?.toJson(),
      );
    }
  }

  /// The file the worker sends for [fileInfo]: the file itself, or, for a file
  /// whose bytes are still on their way, the file once they are saved. Null
  /// when the user gave it up meanwhile, which frees the queue at once.
  /// Throws when the file never arrived and nobody cancelled.
  static Future<FileInfo?> fileToSend(
    FileInfo fileInfo,
    CancelToken cancelToken,
  ) async => fileInfo is PendingFileInfo
      ? fileInfo.whenReady(
          cancelled: () => cancelToken.isCancelled,
          onCancelled: cancelToken.whenCancel,
        )
      : fileInfo;

  /// What becomes of the file a pending upload saved, once it is sent. A
  /// video is sent compressed, so the saved file is not the one that was sent:
  /// it is deleted. Any other file becomes the sender's copy, so the bubble
  /// opens with no download. A failed send keeps it for the retry.
  Future<void> _settleSavedFile(
    Room room,
    FileInfo ready,
    String eventId,
  ) async {
    final savedPath = ready.filePath;
    if (savedPath == null) return;
    if (ready.msgType == MessageTypes.Video) {
      await room.deleteSavedFile(savedPath);
      return;
    }
    await room.moveFileToAppDownloadsFolder(
      eventId: eventId,
      fileName: ready.fileName,
      sourcePath: savedPath,
    );
  }

  void _addFileTaskToWorkerQueueMobile({
    required String txid,
    required SyncUpdate fakeImageEvent,
    required Room room,
    required FileInfo fileInfo,
    required StreamController<Either<Failure, Success>> streamController,
    required CancelToken cancelToken,
    DateTime? sentDate,
    int? shrinkImageMaxDimension,
    String? captionInfo,
    Event? inReplyTo,
    Map<String, dynamic>? uploadInfo,
  }) {
    final info = _eventIdMapUploadFileInfo[txid];
    if (info != null) {
      // A pending file stays `info.fileInfo`: a retry brings it through it,
      // and nothing reads its bytes into memory for a preview.
      info.fileInfo = fileInfo;
      info.shrinkImageMaxDimension = shrinkImageMaxDimension;
    }
    final job = _MobileSendJob(
      txid: txid,
      fakeImageEvent: fakeImageEvent,
      room: room,
      streamController: streamController,
      cancelToken: cancelToken,
      info: info,
      sentDate: sentDate,
      shrinkImageMaxDimension: shrinkImageMaxDimension,
      captionInfo: captionInfo,
      inReplyTo: inReplyTo,
      uploadInfo: uploadInfo,
    );
    if (fileInfo is PendingFileInfo) {
      unawaited(_queueWhenReady(job, fileInfo));
    } else {
      _queueSend(job, fileInfo, saved: false);
    }
  }

  final _pendingOrder = PendingUploadOrder();

  /// A pending file waits for its bytes outside the queue, which is serial
  /// for the whole app: a slow download holds no other upload. Its bubble is
  /// shown meanwhile, and it joins the queue once it is on disk, after the
  /// files of its room shown before it.
  Future<void> _queueWhenReady(
    _MobileSendJob job,
    PendingFileInfo pending,
  ) async {
    try {
      final queued = await _pendingOrder.inTurn(
        job.room.id,
        fileToSend(pending, job.cancelToken),
        (FileInfo? ready) {
          if (ready == null || job.cancelToken.isCancelled) return false;
          _queueSend(job, ready, saved: true);
          return true;
        },
      );
      if (queued) return;
      // Cancelled while its bytes were on their way: the event is gone, so
      // nothing is sent and nothing brings it back.
      job.room.sendingFilePlaceholders.remove(job.txid);
      await _clearFileTask(job.txid);
    } catch (e) {
      _markFailed(job, e);
      job.room.sendingFilePlaceholders.remove(job.txid);
    }
  }

  void _queueSend(_MobileSendJob job, FileInfo ready, {required bool saved}) {
    uploadWorkerQueue.addTask(
      Task(
        id: job.txid,
        runnable: () async {
          try {
            final eventId = await job.room.sendFileEventMobile(
              ready,
              msgType: ready.msgType,
              txid: job.txid,
              fakeImageEvent: job.fakeImageEvent,
              shrinkImageMaxDimension: job.shrinkImageMaxDimension,
              uploadStreamController: job.streamController,
              cancelToken: job.cancelToken,
              sentDate: job.sentDate,
              captionInfo: job.captionInfo,
              inReplyTo: job.inReplyTo,
              uploadInfo: job.uploadInfo,
              extraContent: _batchStamp.contentFor(job.info?.batchId),
            );
            if (eventId == null) {
              throw Exception('Failed to send file event');
            }
            if (saved) await _settleSavedFile(job.room, ready, eventId);
          } catch (e) {
            _markFailed(job, e);
          }
        },
        onTaskCompleted: () async {
          job.room.sendingFilePlaceholders.remove(job.txid);
          if (job.info?.isFailed != true) {
            await _clearFileTask(job.txid);
          }
        },
      ),
    );
  }

  void _markFailed(_MobileSendJob job, Object error) {
    final info = job.info;
    if (info != null) {
      info.isFailed = true;
      _updateEventUploadInfo(job.room, job.txid, info);
    }
    job.streamController.add(
      Left(UploadFileFailedState(exception: error, txid: job.txid)),
    );
  }

  Future<void> _addFileTaskToWorkerQueueWeb({
    required String txid,
    required SyncUpdate fakeImageEvent,
    required Room room,
    required MatrixFile matrixFile,
    required StreamController<Either<Failure, Success>> streamController,
    required CancelToken cancelToken,
    Event? inReplyTo,
    MatrixImageFile? thumbnail,
    DateTime? sentDate,
    String? captionInfo,
    Map<String, dynamic>? uploadInfo,
  }) {
    final info = _eventIdMapUploadFileInfo[txid];
    if (info != null) {
      info.matrixFile = matrixFile;
      info.thumbnail = thumbnail;
    }

    return uploadWorkerQueue.addTask(
      Task(
        id: txid,
        runnable: () async {
          try {
            final eventId = await room.sendFileOnWebEvent(
              matrixFile,
              fakeImageEvent: fakeImageEvent,
              txid: txid,
              thumbnail: thumbnail,
              uploadStreamController: streamController,
              cancelToken: cancelToken,
              sentDate: sentDate,
              captionInfo: captionInfo,
              inReplyTo: inReplyTo,
              extraContent: _batchStamp.contentFor(info?.batchId),
            );
            if (eventId == null) {
              throw Exception('File upload failed');
            }
          } catch (e) {
            if (info != null) {
              info.isFailed = true;
              _updateEventUploadInfo(room, txid, info);
            }
            streamController.add(
              Left(UploadFileFailedState(exception: e, txid: txid)),
            );
          }
        },
        onTaskCompleted: () async {
          room.sendingFilePlaceholders.remove(txid);
          if (info?.isFailed != true) {
            await _clearFileTask(txid);
          }
        },
      ),
    );
  }

  Future<void> _updateEventUploadInfo(
    Room room,
    String eventId,
    UploadFileInfo info,
  ) async {
    try {
      final event = await room.getEventById(eventId);
      if (event != null) {
        final unsigned = Map<String, dynamic>.from(event.unsigned ?? {});
        unsigned['upload_info'] = info.toJson();
        final syncUpdate = SyncUpdate(
          nextBatch: '',
          rooms: RoomsUpdate(
            join: {
              room.id: JoinedRoomUpdate(
                timeline: TimelineUpdate(
                  events: [
                    MatrixEvent(
                      eventId: event.eventId,
                      senderId: event.senderId,
                      originServerTs: event.originServerTs,
                      type: event.type,
                      content: event.content,
                      unsigned: unsigned,
                    ),
                  ],
                ),
              ),
            },
          ),
        );
        await room.client.database.transaction(() async {
          await room.client.handleSync(syncUpdate);
        });
      }
    } catch (e) {
      Logs().e('UploadManager::_updateEventUploadInfo(): $e');
    }
  }
}

/// What one mobile send carries from the queueing of a file to its send.
class _MobileSendJob {
  const _MobileSendJob({
    required this.txid,
    required this.fakeImageEvent,
    required this.room,
    required this.streamController,
    required this.cancelToken,
    required this.info,
    this.sentDate,
    this.shrinkImageMaxDimension,
    this.captionInfo,
    this.inReplyTo,
    this.uploadInfo,
  });

  final String txid;
  final SyncUpdate fakeImageEvent;
  final Room room;
  final StreamController<Either<Failure, Success>> streamController;
  final CancelToken cancelToken;
  final UploadFileInfo? info;
  final DateTime? sentDate;
  final int? shrinkImageMaxDimension;
  final String? captionInfo;
  final Event? inReplyTo;
  final Map<String, dynamic>? uploadInfo;
}
