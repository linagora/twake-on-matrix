import 'dart:async';

import 'package:dartz/dartz.dart' hide Task;
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_info.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/manager/download_manager/downloading_worker_queue.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/task_queue/task.dart';
import 'package:matrix/matrix.dart';

typedef FutureVoidCallback = Future<void> Function();

class DownloadManager {
  DownloadManager._();

  static final DownloadManager _instance = DownloadManager._();

  factory DownloadManager() => _instance;

  final workingQueue = getIt.get<DownloadWorkerQueue>();

  final Map<String, DownloadFileInfo> _eventIdMapDownloadFileInfo = {};

  void cancelDownload(String eventId) {
    final cancelToken = _eventIdMapDownloadFileInfo[eventId]?.cancelToken;
    if (cancelToken != null) {
      try {
        cancelToken.cancel();
        _eventIdMapDownloadFileInfo[eventId]?.downloadStateStreamController.add(
              const Right(
                DownloadFileInitial(),
              ),
            );
      } catch (e) {
        Logs().e(
          'DownloadManager::cancelDownload(): $e',
        );
        _eventIdMapDownloadFileInfo[eventId]?.downloadStateStreamController.add(
              Left(
                DownloadFileFailureState(exception: e),
              ),
            );
      } finally {
        clear(eventId);
      }
    }
  }

  void _initDownloadFileInfo(
    Event event,
  ) {
    final streamController = StreamController<Either<Failure, Success>>();

    _eventIdMapDownloadFileInfo[event.eventId] = DownloadFileInfo(
      eventId: event.eventId,
      cancelToken: CancelToken(),
      downloadStateStreamController: streamController,
      downloadStream: streamController.stream.asBroadcastStream(),
    );
  }

  Stream<Either<Failure, Success>>? getDownloadStateStream(String eventId) {
    return _eventIdMapDownloadFileInfo[eventId]?.downloadStream;
  }

  Future<void> clear(String eventId) async {
    try {
      await _eventIdMapDownloadFileInfo[eventId]
          ?.downloadStateStreamController
          .close();
    } catch (e) {
      Logs().e(
        'DownloadManager::_clear(): $e',
      );
      _eventIdMapDownloadFileInfo[eventId]?.downloadStateStreamController.add(
            Left(
              DownloadFileFailureState(exception: e),
            ),
          );
    } finally {
      _eventIdMapDownloadFileInfo.remove(eventId);
      Logs().i(
        'DownloadManager::clear with $eventId successfully',
      );
    }
  }

  Future<void> download({
    required Event event,
    bool getThumbnail = false,
  }) async {
    _initDownloadFileInfo(event);
    final streamController = _eventIdMapDownloadFileInfo[event.eventId]
        ?.downloadStateStreamController;
    final cancelToken = _eventIdMapDownloadFileInfo[event.eventId]?.cancelToken;
    if (streamController == null || cancelToken == null) {
      Logs().e(
        'DownloadManager::download(): streamController or cancelToken is null',
      );
      _eventIdMapDownloadFileInfo[event.eventId]
          ?.downloadStateStreamController
          .add(
            Left(
              DownloadFileFailureState(
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
        DownloadFileInitial(),
      ),
    );
    _addTaskToWorkerQueue(
      event: event,
      getThumbnail: getThumbnail,
      streamController: streamController,
      cancelToken: cancelToken,
    );
  }

  void _addTaskToWorkerQueue({
    required Event event,
    bool getThumbnail = false,
    required StreamController<Either<Failure, Success>> streamController,
    required CancelToken cancelToken,
  }) {
    if (!PlatformInfos.isWeb) {
      _addTaskToWorkerQueueNative(
        event,
        getThumbnail,
        streamController,
        cancelToken,
      );
      return;
    }

    _addTaskToWorkerQueueWeb(event, streamController);
  }

  void _addTaskToWorkerQueueNative(
    Event event,
    bool getThumbnail,
    StreamController<Either<Failure, Success>> streamController,
    CancelToken cancelToken,
  ) {
    workingQueue.addTask(
      Task(
        id: event.eventId,
        runnable: () async {
          try {
            await event.getFileInfo(
              getThumbnail: getThumbnail,
              downloadStreamController: streamController,
              cancelToken: cancelToken,
            );
          } catch (e) {
            Logs().e('DownloadManager::download(): $e');
            streamController.add(
              Left(
                DownloadFileFailureState(exception: e),
              ),
            );
          }
        },
        onTaskCompleted: () => clear(event.eventId),
      ),
    );
  }

  void _addTaskToWorkerQueueWeb(
    Event event,
    StreamController<Either<Failure, Success>> streamController,
  ) {
    workingQueue.addTask(
      Task(
        id: event.eventId,
        runnable: () async {
          try {
            final matrixFile = await event.downloadAndDecryptAttachment();
            streamController.add(
              Right(
                DownloadMatrixFileSuccessState(matrixFile: matrixFile),
              ),
            );
          } catch (e) {
            Logs().e('DownloadManager::download(): $e');
            streamController.add(
              Left(
                DownloadFileFailureState(exception: e),
              ),
            );
          }
        },
        onTaskCompleted: () => clear(event.eventId),
      ),
    );
  }
}
