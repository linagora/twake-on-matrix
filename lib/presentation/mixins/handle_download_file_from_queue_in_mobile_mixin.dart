import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart' hide State, OpenFile;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/manager/download_manager/download_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/storage_directory_utils.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

typedef OnDownloadedFileDone = void Function(String filePath);

mixin HandleDownloadFileFromQueueInMobileMixin {
  final downloadManager = getIt.get<DownloadManager>();

  final downloadFileStateNotifier = ValueNotifier<DownloadPresentationState>(
    const NotDownloadPresentationState(),
  );

  void onDownloadedFileDone(String filePath) {
    Logs().i(
      'HandleDownloadFileFromQueueInMobileMixin::onDownloadedFile(): $filePath',
    );
  }

  StreamSubscription<Either<Failure, Success>>? streamSubscription;

  void checkDownloadFileState(Event event) async {
    checkFileExistInMemory(event);
    await checkFileInDownloadsInApp(event);

    trySetupDownloadingStreamSubcription(event);
    if (streamSubscription != null) {
      downloadFileStateNotifier.value = const DownloadingPresentationState();
    }
  }

  void checkFileExistInMemory(Event event) {
    final filePathInMem = event.getFilePathFromMem();
    if (filePathInMem?.isNotEmpty == true) {
      downloadFileStateNotifier.value = DownloadedPresentationState(
        filePath: filePathInMem!,
      );
      return;
    }
  }

  Future<void> checkFileInDownloadsInApp(Event event) async {
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

  void trySetupDownloadingStreamSubcription(Event event) {
    streamSubscription = downloadManager
        .getDownloadStateStream(event.eventId)
        ?.listen(setupDownloadingProcess);
  }

  void setupDownloadingProcess(
    Either<Failure, Success> event,
  ) {
    event.fold(
      (failure) {
        Logs().e('MessageDownloadContent::onDownloadingProcess(): $failure');
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
          onDownloadedFileDone.call(success.filePath);
        }
      },
    );
  }

  void onDownloadFileTapped(Event event) async {
    await checkFileInDownloadsInApp(event);
    if (downloadFileStateNotifier.value is DownloadedPresentationState) {
      return;
    }
    downloadFileStateNotifier.value = const DownloadingPresentationState();
    downloadManager.download(
      event: event,
    );
    trySetupDownloadingStreamSubcription(event);
  }
}
