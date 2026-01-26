import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog.dart';
import 'package:fluffychat/presentation/enum/chat/send_media_with_caption_status_enum.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/mime_type_uitls.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:super_clipboard/super_clipboard.dart';

mixin PasteImageMixin {
  Future<void> pasteImage(
    BuildContext context,
    Room room, {
    ClipboardReader? clipboardReader,
    VoidCallback? onSendFileCallback,
    Event? inReplyTo,
  }) async {
    if (!(await TwakeClipboard.instance
        .isReadableImageFormat(clipboardReader: clipboardReader))) {
      TwakeSnackBar.show(context, L10n.of(context)!.fileFormatNotSupported);
      Logs().e('PasteImageMixin::pasteImage(): not readable image format');
      return;
    }
    List<MatrixFile?>? matrixFiles;
    if (PlatformInfos.isWeb) {
      matrixFiles = await TwakeClipboard.instance
          .pasteImagesUsingBytes(reader: clipboardReader);
    }
    if (matrixFiles == null || matrixFiles.isEmpty) {
      TwakeSnackBar.show(context, L10n.of(context)!.pasteImageFailed);
      return;
    }
    final nonNullableFiles = matrixFiles
        .where(
          (matrixFile) => matrixFile != null,
        )
        .map(
          (matrixFile) => MatrixFile(
            name: matrixFile!.name,
            mimeType: MimeTypeUitls.instance.getTwakeMimeType(matrixFile.name),
            bytes: matrixFile.bytes,
          ).detectFileType,
        )
        .cast<MatrixImageFile>()
        .toList();
    final result = await showDialog(
      context: context,
      useRootNavigator: PlatformInfos.isWeb,
      builder: (context) {
        return SendFileDialog(
          room: room,
          files: nonNullableFiles,
          inReplyTo: inReplyTo,
        );
      },
    );
    if (result is SendMediaDialogResult) {
      switch (result.status) {
        case SendMediaWithCaptionStatus.done:
        case SendMediaWithCaptionStatus.emptyRoom:
          onSendFileCallback?.call();
          break;
        case SendMediaWithCaptionStatus.cancel:
          break;
      }
    }
  }
}
