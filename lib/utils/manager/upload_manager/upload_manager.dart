import 'dart:async';
import 'package:dartz/dartz.dart' hide Task;
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/extensions/file_info_extension.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:fluffychat/utils/manager/upload_manager/models/upload_caption_info.dart';
import 'package:fluffychat/utils/manager/upload_manager/models/upload_file_info.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_state.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_worker_queue.dart';
import 'package:fluffychat/utils/task_queue/task.dart';
import 'package:matrix/matrix.dart';
import 'package:rxdart/rxdart.dart';

class UploadManager {
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
    if (_eventIdMapUploadFileInfo.containsKey(eventId)) {
      return _eventIdMapUploadFileInfo[eventId];
    }

    // Attempt to restore on-demand from the event's unsigned data
    final event = await room.getEventById(eventId);
    if (event != null) {
      final uploadInfoMap = event.unsigned?['upload_info'];
      if (uploadInfoMap is Map<String, dynamic>) {
        final info = UploadFileInfo.fromJson(uploadInfoMap);
        _eventIdMapUploadFileInfo[eventId] = info;
        return info;
      }
    }

    return null;
  }

  Future<void> cancelUpload(Event event) async {
    final cancelToken = _eventIdMapUploadFileInfo[event.eventId]?.cancelToken;
    if (cancelToken != null) {
      Logs().d('Remove eventid: ${event.eventId}');
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
      return uploadInfo.matrixFile ?? await uploadInfo.fileInfo?.toMatrixFile();
    } catch (e) {
      Logs().e('Error getting matrix file for eventid $eventId', e);
      return null;
    }
  }

  /// Retries a failed upload
  Future<void> retryUpload(Event event) async {
    final txid = event.eventId;
    if (_retriesInProgress.contains(txid)) {
      Logs().w('Retry already in progress for txid $txid');
      return;
    }
    _retriesInProgress.add(txid);
    try {
      final uploadInfo = await getUploadFileInfo(txid, room: event.room);

      if (uploadInfo == null) {
        throw Exception('Upload with txid $txid not found');
      }

      if (!uploadInfo.isFailed) {
        await event.cancelSend();
        throw Exception('Upload with txid $txid is not in failed state');
      }

      final room = event.room;
      final fileInfo = uploadInfo.fileInfo;
      final matrixFile = uploadInfo.matrixFile;
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
          );
        } else if (matrixFile != null) {
          fakeImageEvent = await room.sendFakeFileEvent(
            matrixFile,
            txid: txid,
            captionInfo: caption,
            uploadInfo: uploadInfo.toJson(),
            inReplyTo: inReplyTo,
          );
        }

        if (fakeImageEvent == null) {
          throw Exception('Missing required retry data for txid $txid');
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
        } else if (matrixFile != null) {
          await _addFileTaskToWorkerQueueWeb(
            txid: txid,
            fakeImageEvent: fakeImageEvent,
            room: room,
            matrixFile: matrixFile,
            streamController: streamController,
            cancelToken: cancelToken,
            thumbnail: uploadInfo.thumbnail,
            sentDate: uploadInfo.createdAt,
            captionInfo: caption,
            uploadInfo: uploadInfo.toJson(),
            inReplyTo: inReplyTo,
          );
        } else {
          throw Exception('No file data found for retry with txid $txid');
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
    );
  }

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

    for (final txid in txids.entries) {
      final txidKey = txid.key;
      final fakeSendingFileInfo = txids[txidKey];
      if (fakeSendingFileInfo == null) {
        continue;
      }

      Logs().d('UploadManager::uploadMediaMobile(): txid: $txidKey');

      final isLastFile = txidKey == txids.keys.last;

      _initUploadFileInfo(
        txid: txidKey,
        room: room,
        captionInfo: isLastFile ? caption : null,
        inReplyTo: isLastFile ? inReplyTo : null,
      );

      final sentDate = _eventIdMapUploadFileInfo[txidKey]?.createdAt;

      final fakeImageEvent = await room.sendFakeFileInfoEvent(
        fakeSendingFileInfo.fileInfo,
        txid: txidKey,
        messageType: fakeSendingFileInfo.messageType,
        sentDate: sentDate,
        captionInfo: _eventIdMapUploadFileInfo[txidKey]?.captionInfo?.caption,
        inReplyTo: isLastFile ? inReplyTo : null,
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
        inReplyTo: isLastFile ? inReplyTo : null,
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
    for (final matrixFile in files.asMap().entries) {
      final txid = room.client.generateUniqueTransactionId();
      final fileIndex = matrixFile.key;
      final fileInfo = matrixFile.value;

      final isLastFile = fileIndex == files.length - 1;

      _initUploadFileInfo(
        txid: txid,
        room: room,
        captionInfo: isLastFile ? caption : null,
        inReplyTo: isLastFile ? inReplyTo : null,
      );

      room.sendingFilePlaceholders[txid] = fileInfo;
      final fakeFileEvent = await room.sendFakeFileEvent(
        fileInfo,
        txid: txid,
        captionInfo: _eventIdMapUploadFileInfo[txid]?.captionInfo?.caption,
        inReplyTo: isLastFile ? inReplyTo : null,
        uploadInfo: _eventIdMapUploadFileInfo[txid]?.toJson(),
      );

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
        return;
      }

      streamController.add(const Right(UploadFileInitial()));

      await Future.wait([
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
          inReplyTo: isLastFile ? inReplyTo : null,
          uploadInfo: _eventIdMapUploadFileInfo[txid]?.toJson(),
        ),
      ]);
    }
  }

  Future<void> uploadFileMobile({
    required Room room,
    required List<FileInfo> fileInfos,
    String? caption,
    Event? inReplyTo,
  }) async {
    for (final fileInfo in fileInfos.asMap().entries) {
      final fileIndex = fileInfo.key;
      final fileValue = fileInfo.value;

      final txid = await room.storePlaceholderFileInMem(fileInfo: fileValue);

      Logs().d('UploadManager::uploadFileMobile(): txid: $txid');

      final isLastFile = fileIndex == fileInfos.length - 1;

      _initUploadFileInfo(
        txid: txid,
        room: room,
        captionInfo: isLastFile ? caption : null,
        inReplyTo: isLastFile ? inReplyTo : null,
      );

      final sentDate = _eventIdMapUploadFileInfo[txid]?.createdAt;

      final fakeEvent = await room.sendFakeFileInfoEvent(
        fileValue,
        txid: txid,
        messageType: fileValue.msgType,
        sentDate: sentDate,
        captionInfo: _eventIdMapUploadFileInfo[txid]?.captionInfo?.caption,
        inReplyTo: isLastFile ? inReplyTo : null,
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
        inReplyTo: isLastFile ? inReplyTo : null,
        uploadInfo: _eventIdMapUploadFileInfo[txid]?.toJson(),
      );
    }
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
      info.fileInfo = fileInfo;
      info.shrinkImageMaxDimension = shrinkImageMaxDimension;
    }

    uploadWorkerQueue.addTask(
      Task(
        id: txid,
        runnable: () async {
          try {
            final eventId = await room.sendFileEventMobile(
              fileInfo,
              msgType: fileInfo.msgType,
              txid: txid,
              fakeImageEvent: fakeImageEvent,
              shrinkImageMaxDimension: shrinkImageMaxDimension,
              uploadStreamController: streamController,
              cancelToken: cancelToken,
              sentDate: sentDate,
              captionInfo: captionInfo,
              inReplyTo: inReplyTo,
              uploadInfo: uploadInfo,
            );
            if (eventId == null) {
              throw Exception('Failed to send file event');
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
          if (info?.isFailed != true) {
            room.sendingFilePlaceholders.remove(txid);
            await _clearFileTask(txid);
          }
        },
      ),
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
          if (info?.isFailed != true) {
            room.sendingFilePlaceholders.remove(txid);
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
