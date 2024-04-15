import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/dialog/downloading_file_dialog.dart';
import 'package:fluffychat/utils/exception/save_to_downloads_exception.dart';
import 'package:fluffychat/utils/exception/storage_permission_exception.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/manager/download_manager/download_manager.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/manager/storage_directory_manager.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:permission_handler/permission_handler.dart';

mixin SaveFileToTwakeAndroidDownloadsFolderMixin {
  void saveSelectedEventToDownloadAndroid(
    BuildContext context,
    Event downloadEvent,
  ) async {
    try {
      await handleAndroidStoragePermission(context);

      final downloadManager = getIt.get<DownloadManager>();
      final downloadingStreamSubscription =
          downloadManager.getDownloadStateStream(
        downloadEvent.eventId,
      );
      if (downloadingStreamSubscription == null) {
        await handleSaveToDownloadsForFileNotInDownloading(
          downloadEvent,
          context: context,
        );
        return;
      }

      handleSaveToDownloadForDownloadingFile(
        downloadingStreamSubscription: downloadingStreamSubscription,
        event: downloadEvent,
        context: context,
      );
    } catch (e) {
      Logs().e('Chat::saveSelectedEventToDownloadAndroid(): $e');
      if (e is! StoragePermissionException) {
        TwakeSnackBar.show(
          context,
          L10n.of(context)!.saveFileToDownloadsError,
        );
      }
    }
  }

  void handleSaveToDownloadForDownloadingFile({
    required BuildContext context,
    required Stream<Either<Failure, Success>> downloadingStreamSubscription,
    required Event event,
  }) {
    final downloadProgressNotifier = ValueNotifier<double?>(0);
    StreamSubscription? streamSubscription;
    streamSubscription = downloadingStreamSubscription.listen(
      (downloadState) {
        _onDownloadingFileStateChange(
          event: event,
          downloadState: downloadState,
          context: context,
          downloadProgressNotifier: downloadProgressNotifier,
          streamSubscription: streamSubscription,
        );
      },
      cancelOnError: true,
    );

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
        await StorageDirectoryManager.instance.getFilePathInAppDownloads(
      eventId: event.eventId,
      fileName: event.filename,
    );
    final file = File(filePath);
    if (!await file.exists()) {
      await handleWhenFileHaveNotDownloaded(
        event,
        context,
        handleDownloadFileDone: (event, context) async {
          return await handleSaveToDownloadsForFileNotInDownloading(
            event,
            context: context,
          );
        },
      );
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
      final twakeFolder = await StorageDirectoryManager.instance
          .getTwakeDownloadsFolderInDevice();
      if (twakeFolder?.isNotEmpty != true) {
        throw SaveToDownloadsException(error: 'Twake folder is empty');
      }
      final twakeFilePath =
          await StorageDirectoryManager.instance.getAvailableFilePath(
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

  Future<void> handleWhenFileHaveNotDownloaded(
    Event event,
    BuildContext context, {
    Future<void> Function(Event event, BuildContext context)?
        handleDownloadFileDone,
  }) async {
    Logs().d(
      'Chat::saveSelectedEventToDownloadAndroid():: File not exists',
    );
    final downloadManager = getIt.get<DownloadManager>();
    await downloadManager.download(
      event: event,
      isFirstPriority: true,
    );

    final downloadStreamController =
        downloadManager.getDownloadStateStream(event.eventId);
    StreamSubscription? streamSubcription;
    final downloadProgressNotifier = ValueNotifier<double?>(0);
    streamSubcription = downloadStreamController?.listen((downloadState) {
      _onDownloadingFileStateChange(
        event: event,
        downloadState: downloadState,
        context: context,
        downloadProgressNotifier: downloadProgressNotifier,
        streamSubscription: streamSubcription,
        handleDownloadFileDone: handleDownloadFileDone,
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

  void _onDownloadingFileStateChange({
    required Event event,
    required Either<Failure, Success> downloadState,
    required BuildContext context,
    required ValueNotifier<double?> downloadProgressNotifier,
    required StreamSubscription? streamSubscription,
    Future<void> Function(Event event, BuildContext context)?
        handleDownloadFileDone,
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
          await handleDownloadFileDone?.call(event, context);
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

  Future<void> handleAndroidStoragePermission(BuildContext context) async {
    if (await PermissionHandlerService()
        .isUserHaveToRequestStoragePermissionAndroid()) {
      final permission = await Permission.storage.request();

      if (permission.isPermanentlyDenied) {
        showDialog(
          useRootNavigator: false,
          context: context,
          builder: (_) {
            return PermissionDialog(
              icon: const Icon(Icons.storage_rounded),
              permission: Permission.storage,
              explainTextRequestPermission: Text(
                L10n.of(context)!.explainPermissionToDownloadFiles(
                  AppConfig.applicationName,
                ),
              ),
              onAcceptButton: () =>
                  PermissionHandlerService().goToSettingsForPermissionActions(),
            );
          },
        );
      }

      if (!permission.isGranted) {
        Logs().i(
          'Chat::saveSelectedEventToDownloadAndroid():: Permission Denied',
        );
        throw StoragePermissionException("Don't have permission to save file");
      }
    }
  }
}
