import 'package:desktop_drop/desktop_drop.dart';
import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/mime_type_uitls.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin DragDrogFileMixin {
  final ValueNotifier<bool> draggingNotifier = ValueNotifier(false);

  void onDragEntered(_) => draggingNotifier.value = true;

  void onDragExited(_) => draggingNotifier.value = false;

  Future<List<MatrixFile>> onDragDone(DropDoneDetails details) async {
    draggingNotifier.value = false;
    final bytesList = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => Future.wait(
        details.files.map(
          (xfile) => xfile.readAsBytes(),
        ),
      ),
    );
    if (bytesList.error != null) return [];

    final matrixFiles = <MatrixFile>[];
    for (var i = 0; i < bytesList.result!.length; i++) {
      matrixFiles.add(
        MatrixFile(
          bytes: bytesList.result![i],
          name: details.files[i].name,
          mimeType:
              MimeTypeUitls.instance.getTwakeMimeType(details.files[i].name),
        ).detectFileType,
      );
    }
    return matrixFiles;
  }

  Future<dynamic> sendImagesWithCaption({
    Room? room,
    required BuildContext context,
    required List<MatrixFile> matrixFiles,
  }) {
    return showDialog(
      context: context,
      useRootNavigator: PlatformInfos.isWeb,
      builder: (context) {
        return SendFileDialog(
          room: room,
          files: matrixFiles,
        );
      },
    );
  }
}
