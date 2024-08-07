import 'dart:async';

import 'package:dartz/dartz.dart' hide Task;
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/extensions/file_info_extension.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
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

  final Map<String, UploadCaptionInfo> _eventIdMapUploadCaptionInfo = {};

  static const int _shrinkImageMaxDimension = 1600;

  Future<void> cancelUpload(Event event) async {
    final cancelToken = _eventIdMapUploadFileInfo[event.eventId]?.cancelToken;
    final captionInfo = _eventIdMapUploadFileInfo[event.eventId]?.captionInfo;
    if (cancelToken != null) {
      Logs().d('Remove eventid: ${event.eventId}');
      _clearFileTask(event.eventId);
      event.remove();
      cancelToken.cancel();
      if (captionInfo != null) {
        _handleCancelCaptionEvent(
          txid: captionInfo.txid,
          room: event.room,
        );
      }
    }
  }

  Future<void> _handleCancelCaptionEvent({
    required String txid,
    required Room room,
  }) async {
    try {
      _clearCaptionTask(txid);
      final captionEvent = await room.getEventById(txid);
      captionEvent?.remove();
    } catch (e) {
      Logs().e(
        'UploadManager::_handleCancelCaptionEvent(): $e',
      );
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

  Future<void> _clearCaptionTask(String eventId) async {
    _eventIdMapUploadCaptionInfo.remove(eventId);
    uploadWorkerQueue.clearTaskInQueue(eventId);
    Logs().i(
      'UploadManager:: Clear with $eventId successfully',
    );
  }

  void _initUploadCaptionInfo({
    required String txid,
    required String caption,
  }) {
    _eventIdMapUploadCaptionInfo[txid] = UploadCaptionInfo(
      txid: txid,
      caption: caption,
    );
  }

  void _initUploadFileInfo({
    required String txid,
    required Room room,
    String? captionInfo,
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
    );
  }

  Stream<Either<Failure, Success>>? getUploadStateStream(String txid) {
    return _eventIdMapUploadFileInfo[txid]?.uploadStream;
  }

  Future<void> uploadMediaMobile({
    required Room room,
    required List<FileAssetEntity> entities,
    String? caption,
  }) async {
    final txids = await room.sendPlaceholdersForImagePickerFiles(
      entities: entities,
    );

    for (final txid in txids.keys.toList().asMap().entries) {
      final fakeSendingFileInfo = txids[txid.value];
      if (fakeSendingFileInfo == null) {
        continue;
      }

      Logs().d('UploadManager::uploadMediaMobile(): txid: ${txid.value}');

      _initUploadFileInfo(
        txid: txid.value,
        room: room,
        captionInfo: txid.key == txids.keys.length - 1 ? caption : null,
      );

      final sentDate = _eventIdMapUploadFileInfo[txid.value]?.createdAt;

      final fakeImageEvent = await room.sendFakeImagePickerFileEvent(
        fakeSendingFileInfo.fileInfo,
        txid: txid.value,
        messageType: fakeSendingFileInfo.messageType,
        sentDate: sentDate,
      );

      final streamController =
          _eventIdMapUploadFileInfo[txid.value]?.uploadStateStreamController;

      final cancelToken = _eventIdMapUploadFileInfo[txid.value]?.cancelToken;

      if (streamController == null || cancelToken == null) {
        Logs().e(
          'DownloadManager::download(): streamController or cancelToken is null',
        );
        _eventIdMapUploadFileInfo[txid.value]?.uploadStateStreamController.add(
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
        txid: txid.value,
        fakeImageEvent: fakeImageEvent,
        room: room,
        fileInfo: fakeSendingFileInfo.fileInfo,
        streamController: streamController,
        cancelToken: cancelToken,
        sentDate: sentDate,
        shrinkImageMaxDimension: _shrinkImageMaxDimension,
      );

      if (_eventIdMapUploadFileInfo[txid.value]?.captionInfo != null) {
        _addCaptionTaskToWorkerQueue(
          room: room,
          messageTxid:
              _eventIdMapUploadFileInfo[txid.value]?.captionInfo?.txid ?? '',
          caption:
              _eventIdMapUploadFileInfo[txid.value]?.captionInfo?.caption ?? '',
        );
      }
    }
  }

  Future<void> uploadFilesWeb({
    required Room room,
    required List<MatrixFile> files,
    Map<MatrixFile, MatrixImageFile?>? thumbnails,
    String? caption,
  }) async {
    for (final matrixFile in files.asMap().entries) {
      final txid = room.client.generateUniqueTransactionId();

      _initUploadFileInfo(
        txid: txid,
        room: room,
        captionInfo: matrixFile.key == files.length - 1 ? caption : null,
      );

      room.sendingFilePlaceholders[txid] = matrixFile.value;
      final fakeFileEvent = await room.sendFakeFileEvent(
        matrixFile.value,
        txid: txid,
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

      _addFileTaskToWorkerQueueWeb(
        txid: txid,
        fakeImageEvent: fakeFileEvent,
        room: room,
        matrixFile: matrixFile.value,
        streamController: streamController,
        cancelToken: cancelToken,
        thumbnail: thumbnails?[matrixFile.value],
        sentDate: sentDate,
      );
      if (_eventIdMapUploadFileInfo[txid]?.captionInfo != null) {
        _addCaptionTaskToWorkerQueue(
          room: room,
          messageTxid: _eventIdMapUploadFileInfo[txid]?.captionInfo?.txid ?? '',
          caption: _eventIdMapUploadFileInfo[txid]?.captionInfo?.caption ?? '',
        );
      }
    }
  }

  Future<void> uploadFileMobile({
    required Room room,
    required List<FileInfo> fileInfos,
    String? caption,
  }) async {
    for (final fileInfo in fileInfos.asMap().entries) {
      final txid = room.storePlaceholderFileInMem(
        fileInfo: fileInfo.value,
      );

      Logs().d('UploadManager::uploadFileMobile(): txid: $txid');

      _initUploadFileInfo(
        txid: txid,
        room: room,
        captionInfo: fileInfo.key == fileInfos.length - 1 ? caption : null,
      );

      final sentDate = _eventIdMapUploadFileInfo[txid]?.createdAt;

      final fakeEvent = await room.sendFakeImagePickerFileEvent(
        fileInfo.value,
        txid: txid,
        messageType: fileInfo.value.msgType,
        sentDate: sentDate,
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
        fileInfo: fileInfo.value,
        streamController: streamController,
        cancelToken: cancelToken,
        sentDate: sentDate,
      );
      if (_eventIdMapUploadFileInfo[txid]?.captionInfo != null) {
        _addCaptionTaskToWorkerQueue(
          room: room,
          messageTxid: _eventIdMapUploadFileInfo[txid]?.captionInfo?.txid ?? '',
          caption: _eventIdMapUploadFileInfo[txid]?.captionInfo?.caption ?? '',
        );
      }
    }
  }

  Future<void> _addCaptionTaskToWorkerQueue({
    required Room room,
    String? messageTxid,
    String? caption,
  }) async {
    if ((messageTxid == null && messageTxid!.isEmpty) ||
        (caption == null && caption!.isEmpty)) {
      return;
    }
    final messageContent = room.getEventContentFromMsgText(message: caption);

    _initUploadCaptionInfo(
      txid: messageTxid,
      caption: caption,
    );

    await room.sendFakeMessage(
      content: messageContent,
      messageId: messageTxid,
    );

    uploadWorkerQueue.addTask(
      Task(
        id: messageTxid,
        runnable: () async {
          try {
            await room.sendMessageContent(
              EventTypes.Message,
              messageContent,
              txid: messageTxid,
            );
          } catch (e) {
            Logs().e(
              'UploadManager::_addCaptionTaskToWorkerQueueMobile(): $e',
            );
          }
        },
        onTaskCompleted: () => _clearCaptionTask(messageTxid),
      ),
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
            );
          } catch (e) {
            streamController.add(
              Left(
                UploadFileFailedState(exception: e),
              ),
            );
          }
        },
        onTaskCompleted: () => _clearFileTask(txid),
      ),
    );
  }

  void _addFileTaskToWorkerQueueWeb({
    required String txid,
    required SyncUpdate fakeImageEvent,
    required Room room,
    required MatrixFile matrixFile,
    required StreamController<Either<Failure, Success>> streamController,
    required CancelToken cancelToken,
    MatrixImageFile? thumbnail,
    DateTime? sentDate,
  }) {
    uploadWorkerQueue.addTask(
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
            );
          } catch (e) {
            streamController.add(
              Left(
                UploadFileFailedState(exception: e),
              ),
            );
          }
        },
        onTaskCompleted: () => _clearFileTask(txid),
      ),
    );
  }
}
