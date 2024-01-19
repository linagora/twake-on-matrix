import 'package:fluffychat/pages/chat/send_file_dialog.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:super_clipboard/super_clipboard.dart';

mixin PasteImageMixin {
  Future<void> pasteImage(
    BuildContext context,
    Room room, {
    ClipboardReader? clipboardReader,
  }) async {
    if (!(await Clipboard.instance
        .isReadableImageFormat(clipboardReader: clipboardReader))) {
      TwakeSnackBar.show(context, L10n.of(context)!.fileFormatNotSupported);
      Logs().e('PasteImageMixin::pasteImage(): not readable image format');
      return;
    }
    List<MatrixFile?>? matrixFiles;
    if (PlatformInfos.isWeb) {
      matrixFiles = await Clipboard.instance
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
          (matrixFile) => MatrixImageFile(
            name: matrixFile!.name,
            mimeType: matrixFile.mimeType,
            bytes: matrixFile.bytes,
          ),
        )
        .cast<MatrixImageFile>()
        .toList();
    await showDialog(
      context: context,
      useRootNavigator: PlatformInfos.isWeb,
      builder: (context) {
        return SendFileDialog(
          room: room,
          files: nonNullableFiles,
        );
      },
    );
  }
}
