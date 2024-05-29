import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog.dart';
import 'package:fluffychat/presentation/enum/chat/send_media_with_caption_status_enum.dart';
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
    VoidCallback? onSendFileCallback,
  }) async {
    if (matrixFilesList.length <= AppConfig.maxFilesSendPerDialog &&
        matrixFilesList.isNotEmpty) {
      final result = await showDialog(
        context: context,
        useRootNavigator: PlatformInfos.isWeb,
        builder: (context) {
          return SendFileDialog(
            room: room,
            files: matrixFilesList,
          );
        },
      );
      onSendFileCallback?.call();
      if (result is SendMediaWithCaptionStatus) {
        switch (result) {
          case SendMediaWithCaptionStatus.done:
            break;
          case SendMediaWithCaptionStatus.error:
            TwakeSnackBar.show(
              context,
              L10n.of(context)!.failedToSendFiles,
            );
            break;
          case SendMediaWithCaptionStatus.cancel:
            break;
        }
      }
    } else if (matrixFilesList.length > AppConfig.maxFilesSendPerDialog) {
      TwakeSnackBar.show(
        context,
        L10n.of(context)!
            .countFilesSendPerDialog(AppConfig.maxFilesSendPerDialog),
      );
    }
  }
}
