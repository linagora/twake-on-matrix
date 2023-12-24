import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/send_file_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:matrix/matrix.dart';

mixin SendFilesWithCaptionWebMixin {
  void sendFileOnWebAction(
    BuildContext context, {
    Room? room,
    required List<MatrixFile> matrixFilesList,
  }) async {
    if (matrixFilesList.length <= AppConfig.maxFilesSendPerDialog &&
        matrixFilesList.isNotEmpty) {
      showDialog(
        context: context,
        useRootNavigator: PlatformInfos.isWeb,
        builder: (context) {
          return SendFileDialog(
            room: room,
            files: matrixFilesList,
          );
        },
      );
    } else if (matrixFilesList.length > AppConfig.maxFilesSendPerDialog) {
      TwakeSnackBar.show(
        context,
        L10n.of(context)!
            .countFilesSendPerDialog(AppConfig.maxFilesSendPerDialog),
      );
    } else {
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.failedToSendFiles,
      );
    }
  }
}
