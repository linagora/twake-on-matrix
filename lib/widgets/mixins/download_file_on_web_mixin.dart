import 'dart:async';

import 'package:dartz/dartz.dart' hide State, OpenFile;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/manager/download_manager/download_manager.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin DownloadFileOnWebMixin<T extends StatefulWidget> on State<T> {
  final downloadManager = getIt.get<DownloadManager>();

  final downloadFileStateNotifier = ValueNotifier<DownloadPresentationState>(
    const NotDownloadPresentationState(),
  );

  StreamSubscription<Either<Failure, Success>>? streamSubscription;

  Event get event;

  void handleDownloadMatrixFileSuccessDone({
    required DownloadMatrixFileSuccessState success,
  });

  @override
  void initState() {
    super.initState();
    _trySetupDownloadingStreamSubcription();
    if (streamSubscription != null) {
      downloadFileStateNotifier.value = const DownloadingPresentationState();
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
        Logs().e('$T::onDownloadingProcess(): $failure');
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
          _handleDownloadMatrixFileSuccessState(success);
        }
      },
    );
  }

  void _handleDownloadMatrixFileSuccessState(
    DownloadMatrixFileSuccessState success,
  ) {
    streamSubscription?.cancel();
    if (mounted) {
      downloadFileStateNotifier.value = FileWebDownloadedPresentationState(
        matrixFile: success.matrixFile,
      );
      downloadFileStateNotifier.dispose();
      handleDownloadMatrixFileSuccessDone(success: success);
      return;
    }

    if (TwakeApp.routerKey.currentContext != null) {
      handleDownloadMatrixFileSuccessDone(success: success);
    }
  }

  void _downloadFile() async {
    downloadFileStateNotifier.value = const DownloadingPresentationState();
    downloadManager.download(
      event: event,
    );
    _trySetupDownloadingStreamSubcription();
  }

  void onDownloadFileTap() {
    final streamSubscribtion = _trySetupDownloadingStreamSubcription();
    if (streamSubscribtion != null) {
      return;
    }
    _downloadFile();
  }

  @override
  void dispose() {
    downloadFileStateNotifier.dispose();
    super.dispose();
  }
}
