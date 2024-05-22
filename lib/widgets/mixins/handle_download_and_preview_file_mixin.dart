import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/preview_file/download_file_for_preview_failure.dart';
import 'package:fluffychat/domain/app_state/preview_file/download_file_for_preview_loading.dart';
import 'package:fluffychat/domain/app_state/preview_file/download_file_for_preview_success.dart';
import 'package:fluffychat/domain/model/preview_file/document_uti.dart';
import 'package:fluffychat/domain/model/preview_file/supported_preview_file_types.dart';
import 'package:fluffychat/domain/usecase/download_file_for_preview_interactor.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:universal_html/html.dart' as html;

mixin HandleDownloadAndPreviewFileMixin {
  void onFileTapped({
    required Event event,
    required BuildContext context,
  }) {
    if (PlatformInfos.isWeb) {
      onFileTappedWeb(event: event, context: context);
    } else {
      onFileTappedMobile(event: event, context: context);
    }
  }

  Future<void> onFileTappedWeb({
    required Event event,
    required BuildContext context,
  }) async {
    return await handlePreviewWeb(event: event, context: context);
  }

  void onFileTappedMobile({
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
              explainTextRequestPermission:
                  Text(L10n.of(context)!.explainStoragePermission),
              icon: const Icon(Icons.preview_outlined),
            );
          },
        );
        if (await permissionHandler.storagePermissionStatus ==
            PermissionStatus.granted) {
          _handleDownloadFileForPreviewMobile(
            event: event,
            context: context,
          );
        }
        break;
      case PermissionStatus.granted:
        _handleDownloadFileForPreviewMobile(
          event: event,
          context: context,
        );
        break;
      case PermissionStatus.permanentlyDenied:
        showDialog(
          useRootNavigator: false,
          context: context,
          builder: (context) {
            return PermissionDialog(
              permission: Permission.storage,
              explainTextRequestPermission:
                  Text(L10n.of(context)!.explainGoToStorageSetting),
              icon: const Icon(Icons.preview_outlined),
            );
          },
        );
        break;
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        break;
      default:
        break;
    }
  }

  Future<void> handlePreviewWeb({
    MatrixFile? matrixFile,
    required Event event,
    required BuildContext context,
  }) async {
    if (!event.hasAttachment) {
      TwakeSnackBar.show(context, L10n.of(context)!.errorPreviewingFile);
      return;
    }

    if (event.mimeType.isPdfFile()) {
      return await previewPdfWeb(context, event, matrixFile: matrixFile);
    }

    await event.saveFile(context, matrixFile: matrixFile);
  }

  void _handleDownloadFileForPreviewMobile({
    required Event event,
    required BuildContext context,
  }) async {
    final downloadFileForPreviewInteractor =
        getIt.get<DownloadFileForPreviewInteractor>();
    final tempDirPath = (await getTemporaryDirectory()).path;
    downloadFileForPreviewInteractor
        .execute(
      event: event,
      tempDirPath: tempDirPath,
    )
        .listen((event) {
      event.fold((failure) {
        if (failure is DownloadFileForPreviewFailure) {
          TwakeSnackBar.show(context, 'Error: ${failure.exception}');
        }
        TwakeDialog.hideLoadingDialog(context);
      }, (success) {
        if (success is DownloadFileForPreviewSuccess) {
          handleDownloadFileForPreviewSuccess(
            filePath: success.downloadFileForPreviewResponse.filePath,
            mimeType: success.downloadFileForPreviewResponse.mimeType,
          );
          TwakeDialog.hideLoadingDialog(context);
        } else if (success is DownloadFileForPreviewLoading) {
          TwakeDialog.showLoadingDialog(context);
        }
      });
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
      _openDownloadedFileForPreviewIos(
        filePath: filePath,
        mimeType: mimeType,
      );
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
    final openResults = await OpenFile.open(
      filePath,
      type: mimeType,
      uti: DocumentUti(SupportedPreviewFileTypes.iOSSupportedTypes[mimeType])
          .value,
    );
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
    Logs().d(
      'ChatController:_openDownloadedFileForPreviewIos(): $filePath',
    );
    await OpenFile.open(
      filePath,
      type: mimeType,
    );
  }

  Future<void> previewPdfWeb(
    BuildContext context,
    Event event, {
    MatrixFile? matrixFile,
  }) async {
    matrixFile ??= (await event.getFile(context)).result;

    if (matrixFile == null || event.sizeString != matrixFile.sizeString) {
      TwakeSnackBar.show(context, L10n.of(context)!.errorGettingPdf);

      return;
    }

    final blob = html.Blob([matrixFile.bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, "_blank");
    html.Url.revokeObjectUrl(url);
  }
}
