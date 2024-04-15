import 'dart:io';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:fluffychat/presentation/mixins/save_file_to_twake_downloads_folder_mixin.dart';
import 'package:fluffychat/utils/exception/save_to_gallery_exception.dart';
import 'package:fluffychat/utils/exception/storage_permission_exception.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/manager/storage_directory_manager.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:gal/gal.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:permission_handler/permission_handler.dart';

mixin SaveMediaToGalleryAndroidMixin
    on SaveFileToTwakeAndroidDownloadsFolderMixin {
  Future<void> saveSelectedEventToGallery(
    BuildContext context,
    Event downloadEvent,
  ) async {
    try {
      if (PlatformInfos.isAndroid) {
        await handleAndroidStoragePermission(context);
      } else if (PlatformInfos.isIOS) {
        await handlePhotoPermissionIOS(context);
      }
      final fileInDownloadsInApp = await getCachedMediaFile(downloadEvent);
      if (!await fileInDownloadsInApp.exists() ||
          await fileInDownloadsInApp.length() != downloadEvent.getFileSize()) {
        await handleWhenFileHaveNotDownloaded(
          downloadEvent,
          context,
          handleDownloadFileDone: (event, context) async {
            await saveMediaToGallery(
              context: context,
              messageType: event.messageType,
              fileInDownloadsInApp: fileInDownloadsInApp,
            );
          },
        );
        return;
      }
      await saveMediaToGallery(
        context: context,
        messageType: downloadEvent.messageType,
        fileInDownloadsInApp: fileInDownloadsInApp,
      );
    } catch (e) {
      Logs().e('Chat::saveSelectedEventToGallery(): $e');
      if (e is! StoragePermissionException) {
        TwakeSnackBar.show(
          context,
          L10n.of(context)!.saveFileToDownloadsError,
        );
      }
    }
  }

  Future<File> getCachedMediaFile(Event event) async {
    if (event.attachmentMxcUrl == null) {
      throw SaveToGalleryException(
        error: 'File not found',
      );
    }
    if (event.room.isRoomEncrypted()) {
      final filePath =
          await StorageDirectoryManager.instance.getDecryptedFilePath(
        eventId: event.eventId,
        fileName: event.filename,
      );
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
    }

    final filePath =
        await StorageDirectoryManager.instance.getFilePathInAppDownloads(
      eventId: event.eventId,
      fileName: event.filename,
    );
    return File(filePath);
  }

  Future<void> saveImageToGallery({
    required File file,
  }) async {
    Logs().i('Chat::saveImageToGallery():: file path: ${file.path}');
    await Gal.putImage(
      file.path,
    );
  }

  Future<void> saveVideoToGallery({
    required File file,
  }) async {
    await Gal.putVideo(
      file.path,
    );
  }

  Future<void> saveMediaToGallery({
    required BuildContext context,
    required File fileInDownloadsInApp,
    required String messageType,
  }) async {
    if (messageType == MessageTypes.Image) {
      await saveImageToGallery(file: fileInDownloadsInApp);
    } else if (messageType == MessageTypes.Video) {
      await saveVideoToGallery(file: fileInDownloadsInApp);
    }

    TwakeSnackBar.show(
      context,
      L10n.of(context)!.fileSavedToGallery,
    );
  }

  Future<void> handlePhotoPermissionIOS(BuildContext context) async {
    final permissionHandlerService = PermissionHandlerService();
    final permissionStatus =
        await permissionHandlerService.requestPhotoAddOnlyPermissionIOS();
    if (permissionStatus.isPermanentlyDenied) {
      showDialog(
        useRootNavigator: false,
        context: context,
        builder: (_) {
          return PermissionDialog(
            icon: const Icon(Icons.photo),
            permission: Permission.photos,
            explainTextRequestPermission: Text(
              L10n.of(context)!.explainPermissionToGallery(
                AppConfig.applicationName,
              ),
            ),
            onAcceptButton: () =>
                permissionHandlerService.goToSettingsForPermissionActions(),
          );
        },
      );
    }
    if (!permissionStatus.isGranted) {
      throw StoragePermissionException('Permission denied');
    }
  }
}
