import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/utils/dialog/downloading_file_dialog.dart';
import 'package:fluffychat/utils/exception/save_to_downloads_exception.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/storage_directory_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

mixin SaveFileToTwakeAndroidDownloadsFolderMixin {
  void handleSaveToDownloadForDownloadingFile({
    required BuildContext context,
    required Stream<Either<Failure, Success>> downloadingStreamSubscription,
    required Event event,
  }) {
    final downloadProgressNotifier = ValueNotifier<double?>(0);
    StreamSubscription? streamSubscription;
    streamSubscription = downloadingStreamSubscription.listen((downloadState) {
      _onDownloadingFileStateChange(
        event: event,
        downloadState: downloadState,
        context: context,
        downloadProgressNotifier: downloadProgressNotifier,
        streamSubscription: streamSubscription,
      );
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DownloadingFileDialog(
        parentContext: context,
        eventId: event.eventId,
        downloadProgressNotifier: downloadProgressNotifier,
      ),
    );
  }

  Future<void> handleSaveToDownloadsForFileNotInDownloading(
    Event event, {
    required BuildContext context,
  }) async {
    final filePath =
        await StorageDirectoryUtils.instance.getFilePathInAppDownloads(
      eventId: event.eventId,
      fileName: event.filename,
    );
    final file = File(filePath);
    if (!await file.exists()) {
      await _handleWhenFileHaveNotDownloaded(event, context);
      return;
    }
    await handleSaveToDownloadsFolderWhenFileExisted(event, file, context);
  }

  Future<void> handleSaveToDownloadsFolderWhenFileExisted(
    Event event,
    File file,
    BuildContext context,
  ) async {
    try {
      final twakeFolder = await StorageDirectoryUtils.instance
          .getTwakeDownloadsFolderInDevice();
      if (twakeFolder?.isNotEmpty != true) {
        throw SaveToDownloadsException(error: 'Twake folder is empty');
      }
      final twakeFilePath =
          await StorageDirectoryUtils.instance.getAvailableFilePath(
        '$twakeFolder/${event.filename}',
      );

      await File(twakeFilePath).create(recursive: true);
      final copiedFile = await file.copy(twakeFilePath);
      Logs().d(
        'Chat::saveSelectedEventToDownloadAndroid():: Copied file - ${copiedFile.path}',
      );
      TwakeSnackBar.show(context, L10n.of(context)!.fileSavedToDownloads);
    } catch (e) {
      Logs().e(
        'Chat::saveSelectedEventToDownloadAndroid():: Error - $e',
      );
      TwakeSnackBar.show(context, L10n.of(context)!.saveFileToDownloadsError);
    }
  }

  Future<void> _handleWhenFileHaveNotDownloaded(
    Event event,
    BuildContext context,
  ) async {
    Logs().d(
      'Chat::saveSelectedEventToDownloadAndroid():: File not exists',
    );
    final downloadStreamController =
        StreamController<Either<Failure, Success>>();
    final cancelDownloadToken = CancelToken();
    StreamSubscription? streamSubcription;
    final downloadProgressNotifier = ValueNotifier<double?>(0);
    streamSubcription = downloadStreamController.stream.listen((downloadState) {
      _onDownloadingFileStateChange(
        event: event,
        downloadState: downloadState,
        context: context,
        downloadProgressNotifier: downloadProgressNotifier,
        streamSubscription: streamSubcription,
      );
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DownloadingFileDialog(
        parentContext: context,
        eventId: event.eventId,
        downloadProgressNotifier: downloadProgressNotifier,
        cancelDownloadToken: cancelDownloadToken,
      ),
    );
    await event.getFileInfo(
      downloadStreamController: downloadStreamController,
      cancelToken: cancelDownloadToken,
    );
  }

  void _onDownloadingFileStateChange({
    required Event event,
    required Either<Failure, Success> downloadState,
    required BuildContext context,
    required ValueNotifier<double?> downloadProgressNotifier,
    required StreamSubscription? streamSubscription,
  }) {
    downloadState.fold(
      (left) {
        Logs().e(
          'Chat::saveSelectedEventToDownloadAndroid():: Downloading - $left',
        );
        _clear(
          downloadProgressNotifier: downloadProgressNotifier,
          streamSubscription: streamSubscription,
        );
      },
      (right) async {
        if (right is DownloadingFileState) {
          if (right.total == 0) return null;
          downloadProgressNotifier.value = right.receive / right.total;
        } else if (right is DownloadNativeFileSuccessState) {
          _clear(
            downloadProgressNotifier: downloadProgressNotifier,
            streamSubscription: streamSubscription,
          );
          Navigator.of(context, rootNavigator: true).pop();
          await handleSaveToDownloadsForFileNotInDownloading(
            event,
            context: context,
          );
        }
      },
    );
  }

  void _clear({
    ValueNotifier<double?>? downloadProgressNotifier,
    StreamSubscription? streamSubscription,
  }) {
    downloadProgressNotifier?.dispose();
    streamSubscription?.cancel();
  }
}
