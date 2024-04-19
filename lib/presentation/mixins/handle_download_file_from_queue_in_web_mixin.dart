import 'dart:async';

import 'package:dartz/dartz.dart' hide State, OpenFile;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/manager/download_manager/download_manager.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:matrix/matrix.dart';

mixin HandleDownloadFileFromQueueInWebMixin {
  final downloadManager = getIt.get<DownloadManager>();

  final downloadFileStateNotifier = ValueNotifier<DownloadPresentationState>(
    const NotDownloadPresentationState(),
  );

  StreamSubscription<Either<Failure, Success>>? streamSubscription;

  void handleDownloadMatrixFileSuccessDone({
    required DownloadMatrixFileSuccessState success,
  }) {
    Logs().i('MessageDownloadContent::handleDownloadMatrixFileSuccessDone()');
  }

  void trySetupDownloadingStreamSubcription(String eventId) {
    streamSubscription = downloadManager
        .getDownloadStateStream(eventId)
        ?.listen(setupDownloadingProcess);
  }

  void setupDownloadingProcess(Either<Failure, Success> event) {
    event.fold(
      (failure) {
        Logs().e('MessageDownloadContent::onDownloadingProcess(): $failure');
        downloadFileStateNotifier.value = const NotDownloadPresentationState();
      },
      (success) {
        if (success is DownloadingFileState) {
          if (success.total != 0) {
            downloadFileStateNotifier.value = DownloadingPresentationState(
              receive: success.receive,
              total: success.total,
            );
          }
        } else if (success is DownloadMatrixFileSuccessState) {
          handleDownloadMatrixFileSuccessDone(success: success);
        }
      },
    );
  }

  void onDownloadFileTapped(Event event) {
    downloadFileStateNotifier.value = const DownloadingPresentationState();
    downloadManager.download(
      event: event,
    );
    trySetupDownloadingStreamSubcription(event.eventId);
  }
}
