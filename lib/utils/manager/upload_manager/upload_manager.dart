import 'dart:async';

import 'package:dartz/dartz.dart' hide Task;
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/extensions/file_info_extension.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
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
    if (cancelToken != null) {
      Logs().d('Remove eventid: ${event.eventId}');
      cancelToken.cancel();
      _clearFileTask(event.eventId);
      event.remove();
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
        'UploadManager::_clear(): $e',
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
  }) {
    final uploadController = StreamController<Either<Failure, Success>>();

    _eventIdMapUploadFileInfo[txid] = UploadFileInfo(
      txid: txid,
      uploadStateStreamController: uploadController,
      uploadStream: uploadController.stream.asBroadcastStream(),
      cancelToken: CancelToken(),
      createdAt: DateTime.now(),
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

    for (final txid in txids.keys) {
      final fakeSendingFileInfo = txids[txid];
      if (fakeSendingFileInfo == null) {
        continue;
      }

      Logs().d('UploadManager::uploadMediaMobile(): txid: $txid');

      _initUploadFileInfo(txid: txid);

      final sentDate = _eventIdMapUploadFileInfo[txid]?.createdAt;

      final fakeImageEvent = await room.sendFakeImagePickerFileEvent(
        fakeSendingFileInfo.fileInfo,
        txid: txid,
        messageType: fakeSendingFileInfo.messageType,
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
        fakeImageEvent: fakeImageEvent,
        room: room,
        fileInfo: fakeSendingFileInfo.fileInfo,
        streamController: streamController,
        cancelToken: cancelToken,
        sentDate: sentDate,
        shrinkImageMaxDimension: _shrinkImageMaxDimension,
      );
    }
    if (caption != null && caption.isNotEmpty) {
      _addCaptionTaskToWorkerQueueMobile(
        room: room,
        caption: caption,
      );
    }
  }

  Future<void> uploadFileMobile({
    required Room room,
    required List<FileInfo> fileInfos,
    String? caption,
  }) async {
    for (final fileInfo in fileInfos) {
      final txid = room.storePlaceholderFileInMem(
        fileInfo: fileInfo,
      );

      Logs().d('UploadManager::uploadFileMobile(): txid: $txid');

      _initUploadFileInfo(txid: txid);

      final sentDate = _eventIdMapUploadFileInfo[txid]?.createdAt;

      final fakeImageEvent = await room.sendFakeImagePickerFileEvent(
        fileInfo,
        txid: txid,
        messageType: fileInfo.msgType,
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
        fakeImageEvent: fakeImageEvent,
        room: room,
        fileInfo: fileInfo,
        streamController: streamController,
        cancelToken: cancelToken,
        sentDate: sentDate,
      );
    }
    if (caption != null && caption.isNotEmpty) {
      _addCaptionTaskToWorkerQueueMobile(
        room: room,
        caption: caption,
      );
    }
  }

  Future<void> _addCaptionTaskToWorkerQueueMobile({
    required Room room,
    required String caption,
  }) async {
    final messageTxid = room.client.generateUniqueTransactionId();

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
}
