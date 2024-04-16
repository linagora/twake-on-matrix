import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart' hide State, OpenFile;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/manager/download_manager/download_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/storage_directory_utils.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin DownloadFileOnMobileMixin {
  final downloadManager = getIt.get<DownloadManager>();

  final downloadFileStateNotifier = ValueNotifier<DownloadPresentationState>(
    const NotDownloadPresentationState(),
  );

  StreamSubscription<Either<Failure, Success>>? streamSubscription;

  void checkDownloadFileState({
    required Event event,
  }) async {
    checkFileExistInMemory(event: event);
    await checkFileInDownloadsInApp(
      event: event,
    );

    _trySetupDownloadingStreamSubcription(event.eventId);
    if (streamSubscription != null) {
      downloadFileStateNotifier.value = const DownloadingPresentationState();
    }
  }

  void checkFileExistInMemory({
    required Event event,
  }) {
    final filePathInMem = event.getFilePathFromMem();
    if (filePathInMem?.isNotEmpty == true) {
      downloadFileStateNotifier.value = DownloadedPresentationState(
        filePath: filePathInMem!,
      );
      return;
    }
  }

  Future<void> checkFileInDownloadsInApp({
    required Event event,
  }) async {
    final filePath =
        await StorageDirectoryUtils.instance.getFilePathInAppDownloads(
      eventId: event.eventId,
      fileName: event.filename,
    );
    final file = File(filePath);
    if (await file.exists() && await file.length() == event.getFileSize()) {
      downloadFileStateNotifier.value = DownloadedPresentationState(
        filePath: filePath,
      );
      return;
    }
  }

  void _trySetupDownloadingStreamSubcription(String eventId) {
    streamSubscription = downloadManager
        .getDownloadStateStream(eventId)
        ?.listen(setupDownloadingProcess);
  }

  void setupDownloadingProcess(Either<Failure, Success> event) {
    event.fold(
      (failure) {
        Logs().e('setupDownloadingProcess::onDownloadingProcess(): $failure');
        downloadFileStateNotifier.value = const NotDownloadPresentationState();
        streamSubscription?.cancel();
      },
      (success) {
        if (success is DownloadingFileState) {
          if (success.total != 0) {
            downloadFileStateNotifier.value = DownloadingPresentationState(
              receive: success.receive,
              total: success.total,
            );
          }
        } else if (success is DownloadNativeFileSuccessState) {
          downloadFileStateNotifier.value = DownloadedPresentationState(
            filePath: success.filePath,
          );
        }
      },
    );
  }

  void onDownloadFileTap({
    required Event event,
  }) async {
    await checkFileInDownloadsInApp(
      event: event,
    );
    if (downloadFileStateNotifier.value is DownloadedPresentationState) {
      return;
    }
    downloadFileStateNotifier.value = const DownloadingPresentationState();
    downloadManager.download(
      event: event,
    );
    _trySetupDownloadingStreamSubcription(event.eventId);
  }
}
