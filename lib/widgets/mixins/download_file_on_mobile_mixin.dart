import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart' hide State, OpenFile;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/manager/storage_directory_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/manager/download_manager/download_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin DownloadFileOnMobileMixin<T extends StatefulWidget> on State<T> {
  final downloadManager = getIt.get<DownloadManager>();

  final downloadFileStateNotifier = ValueNotifier<DownloadPresentationState>(
    const NotDownloadPresentationState(),
  );

  StreamSubscription<Either<Failure, Success>>? streamSubscription;

  Event get event;

  void onDownloadedFileDone(String filePath) {
    Logs().i(
      'HandleDownloadFileFromQueueInMobileMixin::onDownloadedFile(): $filePath',
    );
  }

  @override
  void initState() {
    super.initState();
    checkDownloadFileState();
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    downloadFileStateNotifier.dispose();
    super.dispose();
  }

  void checkDownloadFileState() async {
    checkFileExistInMemory();
    await checkFileInDownloadsInApp();

    _trySetupDownloadingStreamSubcription();
    if (streamSubscription != null) {
      downloadFileStateNotifier.value = const DownloadingPresentationState();
    }
  }

  bool checkFileExistInMemory() {
    final filePathInMem = event.getFilePathFromMem();
    if (filePathInMem?.isNotEmpty == true) {
      downloadFileStateNotifier.value = DownloadedPresentationState(
        filePath: filePathInMem!,
      );
      return true;
    }
    return false;
  }

  Future<void> checkFileInDownloadsInApp() async {
    final filePath =
        await StorageDirectoryManager.instance.getFilePathInAppDownloads(
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

  StreamSubscription<Either<Failure, Success>>?
      _trySetupDownloadingStreamSubcription() =>
          streamSubscription = downloadManager
              .getDownloadStateStream(event.eventId)
              ?.listen(setupDownloadingProcess);

  void setupDownloadingProcess(Either<Failure, Success> resultEvent) {
    resultEvent.fold(
      (failure) {
        Logs()
            .e('$T::setupDownloadingProcess::onDownloadingProcess(): $failure');
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

  void _downloadFile() async {
    await checkFileInDownloadsInApp();
    if (downloadFileStateNotifier.value is DownloadedPresentationState) {
      return;
    }
    downloadFileStateNotifier.value = const DownloadingPresentationState();
    downloadManager.download(
      event: event,
    );
    _trySetupDownloadingStreamSubcription();
  }

  void onDownloadFileTap() async {
    final streamSubscribtion = _trySetupDownloadingStreamSubcription();
    if (streamSubscribtion != null) {
      return;
    }
    _downloadFile();
  }
}
