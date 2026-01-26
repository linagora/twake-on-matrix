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

class UploadManager {
  UploadManager._();

  static final UploadManager _instance = UploadManager._();

  factory UploadManager() => _instance;

  final uploadWorkerQueue = getIt.get<UploadWorkerQueue>();

  final Map<String, UploadFileInfo> _eventIdMapUploadFileInfo = {};

  static const int _shrinkImageMaxDimension = 1600;

  Future<void> cancelUpload(Event event) async {
    final cancelToken = _eventIdMapUploadFileInfo[event.eventId]?.cancelToken;
    if (cancelToken != null) {
      Logs().d('Remove eventid: ${event.eventId}');
      _clearFileTask(event.eventId);
      event.remove();
      cancelToken.cancel();
    }
  }

  Future<void> _clearFileTask(String eventId) async {
    try {
      uploadWorkerQueue.clearTaskInQueue(eventId);
      await _eventIdMapUploadFileInfo[eventId]
          ?.uploadStateStreamController
          .close();
    } catch (e) {
      Logs().e(
        'UploadManager::_clear(): Error $e',
      );
    } finally {
      _eventIdMapUploadFileInfo.remove(eventId);
      Logs().i(
        'UploadManager:: Clear with $eventId successfully',
      );
    }
  }

  void _initUploadFileInfo({
    required String txid,
    required Room room,
    String? captionInfo,
    Event? inReplyTo,
  }) {
    final uploadController = StreamController<Either<Failure, Success>>();

    _eventIdMapUploadFileInfo[txid] = UploadFileInfo(
      txid: txid,
      uploadStateStreamController: uploadController,
      uploadStream: uploadController.stream.asBroadcastStream(),
      cancelToken: CancelToken(),
      createdAt: DateTime.now(),
      captionInfo: captionInfo != null && captionInfo.isNotEmpty
          ? UploadCaptionInfo(
              txid: room.client.generateUniqueTransactionId(),
              caption: captionInfo,
            )
          : null,
      inReplyTo: inReplyTo,
    );
  }

  Stream<Either<Failure, Success>>? getUploadStateStream(String txid) {
    return _eventIdMapUploadFileInfo[txid]?.uploadStream;
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
                  exception: Exception(
                    'streamController or cancelToken is null',
                  ),
                ),
              ),
            );
        return;
      }

      streamController.add(
        const Right(
          UploadFileInitial(),
        ),
      );

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
                  exception: Exception(
                    'streamController or cancelToken is null',
                  ),
                ),
              ),
            );
        return;
      }

      streamController.add(
        const Right(
          UploadFileInitial(),
        ),
      );

      await Future.wait(
        [
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
          ),
        ],
      );
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

      final txid = await room.storePlaceholderFileInMem(
        fileInfo: fileValue,
      );

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
                  exception: Exception(
                    'streamController or cancelToken is null',
                  ),
                ),
              ),
            );
        return;
      }

      streamController.add(
        const Right(
          UploadFileInitial(),
        ),
      );

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
  }) {
    uploadWorkerQueue.addTask(
      Task(
        id: txid,
        runnable: () async {
          try {
            await room.sendFileEventMobile(
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
            );
          } catch (e) {
            streamController.add(
              Left(
                UploadFileFailedState(exception: e),
              ),
            );
          }
        },
        onTaskCompleted: () async {
          room.sendingFilePlaceholders.remove(txid);
          await _clearFileTask(txid);
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
  }) {
    return uploadWorkerQueue.addTask(
      Task(
        id: txid,
        runnable: () async {
          try {
            await room.sendFileOnWebEvent(
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
          } catch (e) {
            streamController.add(
              Left(
                UploadFileFailedState(exception: e),
              ),
            );
          }
        },
        onTaskCompleted: () async {
          room.sendingFilePlaceholders.remove(txid);
          await _clearFileTask(txid);
        },
      ),
    );
  }
}
