import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/preview_file/download_file_for_preview_failure.dart';
import 'package:twake_chat/domain/app_state/preview_file/download_file_for_preview_loading.dart';
import 'package:twake_chat/domain/app_state/preview_file/download_file_for_preview_success.dart';
import 'package:twake_chat/domain/model/preview_file/supported_preview_file_types.dart';
import 'package:twake_chat/domain/usecase/download_file_for_preview_interactor.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/permission_dialog.dart';
import 'package:twake_chat/utils/permission_service.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

mixin HandleDownloadAndPreviewFileMixin {
  void onFileTapped({
    required Event event,
    required BuildContext context,
  }) async {
    final permissionHandler = PermissionHandlerService();
    if (await permissionHandler.noNeedStoragePermission()) {
      return _handleDownloadFileForPreviewMobile(
        event: event,
        context: context,
      );
    }
    final storagePermissionStatus =
        await permissionHandler.storagePermissionStatus;
    switch (storagePermissionStatus) {
      case PermissionStatus.denied:
        await showDialog(
          useRootNavigator: false,
          context: context,
          builder: (context) {
            return PermissionDialog(
              permission: Permission.storage,
              explainTextRequestPermission: Text(
                L10n.of(context)!.explainStoragePermission,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              icon: const Icon(Icons.preview_outlined),
            );
          },
        );
        if (await permissionHandler.storagePermissionStatus ==
            PermissionStatus.granted) {
          _handleDownloadFileForPreviewMobile(event: event, context: context);
        }
        break;
      case PermissionStatus.granted:
        _handleDownloadFileForPreviewMobile(event: event, context: context);
        break;
      case PermissionStatus.permanentlyDenied:
        showDialog(
          useRootNavigator: false,
          context: context,
          builder: (context) {
            return PermissionDialog(
              permission: Permission.storage,
              explainTextRequestPermission: Text(
                L10n.of(context)!.explainGoToStorageSetting,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              icon: const Icon(Icons.preview_outlined),
            );
          },
        );
        break;
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        break;
    }
  }

  void _handleDownloadFileForPreviewMobile({
    required Event event,
    required BuildContext context,
  }) async {
    final downloadFileForPreviewInteractor = getIt
        .get<DownloadFileForPreviewInteractor>();
    final tempDirPath = (await getTemporaryDirectory()).path;
    downloadFileForPreviewInteractor
        .execute(event: event, tempDirPath: tempDirPath)
        .listen((event) {
          event.fold(
            (failure) {
              if (failure is DownloadFileForPreviewFailure) {
                TwakeSnackBar.show(context, 'Error: ${failure.exception}');
              }
              TwakeDialog.hideLoadingDialog(context);
            },
            (success) {
              if (success is DownloadFileForPreviewSuccess) {
                handleDownloadFileForPreviewSuccess(
                  filePath: success.downloadFileForPreviewResponse.filePath,
                  mimeType: success.downloadFileForPreviewResponse.mimeType,
                );
                TwakeDialog.hideLoadingDialog(context);
              } else if (success is DownloadFileForPreviewLoading) {
                TwakeDialog.showLoadingDialog(context);
              }
            },
          );
        });
  }

  void handleDownloadFileForPreviewSuccess({
    required String filePath,
    required String? mimeType,
  }) {
    if (PlatformInfos.isAndroid) {
      _openDownloadedFileForPreviewAndroid(
        filePath: filePath,
        mimeType: mimeType,
      );
      return;
    }

    if (PlatformInfos.isIOS) {
      _openDownloadedFileForPreviewIos(filePath: filePath, mimeType: mimeType);
      return;
    }
  }

  void _openDownloadedFileForPreviewAndroid({
    required String filePath,
    required String? mimeType,
  }) async {
    if (SupportedPreviewFileTypes.apkMimeTypes.contains(mimeType)) {
      await Share.shareXFiles([XFile(filePath)]);
      return;
    }
    final openResults = await OpenFile.open(filePath, type: mimeType);
    Logs().d(
      'ChatController:_openDownloadedFileForPreviewAndroid(): ${openResults.message}',
    );

    if (openResults.type != ResultType.done) {
      await Share.shareXFiles([XFile(filePath)]);
      return;
    }
  }

  void _openDownloadedFileForPreviewIos({
    required String filePath,
    required String? mimeType,
  }) async {
    Logs().d('ChatController:_openDownloadedFileForPreviewIos(): $filePath');
    await OpenFile.open(filePath, type: mimeType);
  }
}
