import 'dart:typed_data';

import 'package:fluffychat/pages/chat/send_file_dialog.dart';
import 'package:fluffychat/presentation/model/clipboard/clipboard_image_info.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

mixin PasteImageMixin {
  Future<void> pasteImage(BuildContext context, Room room) async {
    await Clipboard.instance.initReader();
    if (!(await Clipboard.instance.isReadableImageFormat())) {
      Logs().e('PasteImageMixin::pasteImage(): not readable image format');
      return;
    }
    Uint8List? imageData;
    ClipboardImageInfo? imageClipboard;
    if (PlatformInfos.isWeb) {
      imageData = await Clipboard.instance.pasteImageUsingBytes();
    } else {
      imageClipboard = await Clipboard.instance.pasteImageUsingStream();
      if (imageClipboard == null) {
        TwakeSnackBar.show(context, L10n.of(context)!.pasteImageFailed);
        return;
      }
      // FIXME: need to update the SendFileDialog to have FileInfo inside
      // after update we can use stream to read files instead of convert into raw image data
      final data = await imageClipboard.stream.toList();
      imageData = Uint8List.fromList(
        data.expand((Uint8List uint8List) => uint8List).toList(),
      );
    }
    if (imageData == null || imageData.isEmpty) {
      TwakeSnackBar.show(context, L10n.of(context)!.pasteImageFailed);
      return;
    }

    await showDialog(
      context: context,
      useRootNavigator: PlatformInfos.isWeb,
      builder: (context) {
        return SendFileDialog(
          room: room,
          files: [
            MatrixImageFile(
              name: imageClipboard?.fileName ?? 'copied',
              bytes: imageData,
            )
          ],
        );
      },
    );
  }
}
