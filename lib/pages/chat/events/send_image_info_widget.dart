import 'dart:io';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart' hide Visibility;

class SendingImageWidget extends StatelessWidget {
  SendingImageWidget({
    super.key,
    required this.matrixFile,
    required this.event,
    this.onTapPreview,
  });

  final MatrixImageFile matrixFile;

  final Event event;

  final void Function()? onTapPreview;

  final ValueNotifier<double> sendingFileProgressNotifier = ValueNotifier(0);

  void _onTap(BuildContext context) async {
    if (onTapPreview != null) {
      await showGeneralDialog(
        context: context,
        useRootNavigator: false,
        barrierDismissible: true,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, animationOne, animationTwo) =>
            ImageViewer(event, filePath: matrixFile.filePath),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (event.status == EventStatus.sent ||
        event.status == EventStatus.synced) {
      sendingFileProgressNotifier.value = 1;
    }

    return ValueListenableBuilder<double>(
      key: ValueKey(event.eventId),
      valueListenable: sendingFileProgressNotifier,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            child!,
            if (sendingFileProgressNotifier.value != 1) ...[
              CircularProgressIndicator(
                strokeWidth: 2,
                color: LinagoraRefColors.material().primary[100],
              ),
              Icon(
                Icons.close,
                color: LinagoraRefColors.material().primary[100],
              ),
            ]
          ],
        );
      },
      child: InkWell(
        onTap: () => _onTap(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.file(
            File(matrixFile.filePath!),
            width: MessageContentStyle.imageBubbleWidth,
            height: MessageContentStyle.imageBubbleHeight,
            cacheHeight: MessageContentStyle.imageBubbleHeight.toInt(),
            cacheWidth: MessageContentStyle.imageBubbleWidth.toInt(),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
