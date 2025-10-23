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
import 'package:uuid/uuid.dart';

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
              caption: captionInfo,
            )
          : null,
    );
  }

  Stream<Either<Failure, Success>>? getUploadStateStream(String txid) {
    return _eventIdMapUploadFileInfo[txid]?.uploadStream;
  }

  /// Generates a unique group ID for grouping multiple images together
  /// This ID will be used to identify which images belong to the same group
  String generateGroupId() {
    return const Uuid().v4();
  }

  Future<void> uploadMediaMobile({
    required Room room,
    required List<FileAssetEntity> entities,
    String? caption,
  }) async {
    // Generate a unique group ID for this batch of images
    final groupId = entities.length > 1 ? generateGroupId() : null;

    Logs().d(
      'UploadManager::uploadMediaMobile(): Uploading ${entities.length} files with groupId: $groupId',
    );

    final txids = await room.sendPlaceholdersForImagePickerFiles(
      entities: entities,
      captionInfo: caption,
      extraContent: {
        if (groupId != null) 'image_bubble_id': groupId,
      },
    );

    for (final txid in txids.entries) {
      final txidKey = txid.key;
      final fakeSendingFileInfo = txids[txidKey];
      if (fakeSendingFileInfo == null) {
        continue;
      }

      Logs().d('UploadManager::uploadMediaMobile(): txid: $txidKey');

      _initUploadFileInfo(
        txid: txidKey,
        room: room,
        captionInfo: txidKey == txids.keys.last ? caption : null,
      );

      final sentDate = _eventIdMapUploadFileInfo[txidKey]?.createdAt;

      final fakeImageEvent = await room.sendFakeFileInfoEvent(
        fakeSendingFileInfo.fileInfo,
        txid: txidKey,
        messageType: fakeSendingFileInfo.messageType,
        sentDate: sentDate,
        captionInfo: _eventIdMapUploadFileInfo[txidKey]?.captionInfo?.caption,
        extraContent: {
          if (groupId != null) 'image_bubble_id': groupId,
        },
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
        extraContent: {
          if (groupId != null) 'image_bubble_id': groupId,
        },
      );
    }
  }

  Future<void> uploadFilesWeb({
    required Room room,
    required List<MatrixFile> files,
    Map<MatrixFile, MatrixImageFile?>? thumbnails,
    String? caption,
  }) async {
    // Generate a unique group ID for this batch of images
    final groupId = files.length > 1 ? generateGroupId() : null;

    print(
      'UploadManager::uploadMediaMobile(): Uploading ${files.length} files with groupId: $groupId',
    );

    for (final matrixFile in files.asMap().entries) {
      final txid = room.client.generateUniqueTransactionId();
      final fileIndex = matrixFile.key;
      final fileInfo = matrixFile.value;

      _initUploadFileInfo(
        txid: txid,
        room: room,
        captionInfo: fileIndex == files.length - 1 ? caption : null,
      );

      room.sendingFilePlaceholders[txid] = fileInfo;
      final fakeFileEvent = await room.sendFakeFileEvent(
        fileInfo,
        txid: txid,
        captionInfo: _eventIdMapUploadFileInfo[txid]?.captionInfo?.caption,
        extraContent: {
          if (groupId != null) 'image_bubble_id': groupId,
        },
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
          extraContent: {
            if (groupId != null) 'image_bubble_id': groupId,
          },
        ),
      ]);
    }
  }

  Future<void> uploadFileMobile({
    required Room room,
    required List<FileInfo> fileInfos,
    String? caption,
  }) async {
    for (final fileInfo in fileInfos.asMap().entries) {
      final fileIndex = fileInfo.key;
      final fileValue = fileInfo.value;

      final txid = room.storePlaceholderFileInMem(
        fileInfo: fileValue,
      );

      Logs().d('UploadManager::uploadFileMobile(): txid: $txid');

      _initUploadFileInfo(
        txid: txid,
        room: room,
        captionInfo: fileIndex == fileInfos.length - 1 ? caption : null,
      );

      final sentDate = _eventIdMapUploadFileInfo[txid]?.createdAt;

      final fakeEvent = await room.sendFakeFileInfoEvent(
        fileValue,
        txid: txid,
        messageType: fileValue.msgType,
        sentDate: sentDate,
        captionInfo: _eventIdMapUploadFileInfo[txid]?.captionInfo?.caption,
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
    Map<String, dynamic>? extraContent,
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
              extraContent: extraContent,
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

  Future<void> _addFileTaskToWorkerQueueWeb({
    required String txid,
    required SyncUpdate fakeImageEvent,
    required Room room,
    required MatrixFile matrixFile,
    required StreamController<Either<Failure, Success>> streamController,
    required CancelToken cancelToken,
    MatrixImageFile? thumbnail,
    DateTime? sentDate,
    String? captionInfo,
    Map<String, dynamic>? extraContent,
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
              extraContent: extraContent,
            );
          } catch (e) {
            streamController.add(
              Left(
                UploadFileFailedState(exception: e),
              ),
            );
          }
        },
        onTaskCompleted: () {
          room.sendingFilePlaceholders.remove(txid);
          _clearFileTask(txid);
        },
      ),
    );
  }
}
