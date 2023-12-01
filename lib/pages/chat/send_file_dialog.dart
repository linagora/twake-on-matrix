import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/send_media_on_web_with_caption_interactor.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/send_file_dialog_view.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import '../../utils/resize_image.dart';

class SendFileDialog extends StatefulWidget {
  final Room? room;
  final List<MatrixFile> files;

  const SendFileDialog({
    this.room,
    required this.files,
    Key? key,
  }) : super(key: key);

  @override
  SendFileDialogController createState() => SendFileDialogController();
}

class SendFileDialogController extends State<SendFileDialog> {
  bool origImage = false;

  /// Images smaller than 20kb don't need compression.
  static const int minSizeToCompress = 20 * 1024;

  final sendMediaOnWebWithCaptionInteractor =
      getIt.get<SendMediaOnWebWithCaptionInteractor>();

  final focusSuggestionController = FocusSuggestionController();

  final TextEditingController textEditingController = TextEditingController();

  void sendMediaWithCaption() {
    if (widget.room == null) {
      Logs().e("sendMediaWithCaption:: room is null");
      Navigator.of(context).pop();
      return;
    }
    sendMediaOnWebWithCaptionInteractor.execute(
      room: widget.room!,
      media: widget.files.first,
      caption: textEditingController.text,
    );
    Navigator.of(context).pop();
  }

  Future<void> sendWithoutCaption() async {
    for (var file in widget.files) {
      // ignore: unused_local_variable
      MatrixImageFile? thumbnail;
      if (file is MatrixVideoFile &&
          (file.bytes?.length ?? 0) > minSizeToCompress) {
        await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () async {
            file = await file.resizeVideo();
            thumbnail = await file.getVideoThumbnail();
          },
        );
      }
      if (widget.room == null) {
        Logs().e("sendMediaWithCaption:: room is null");
        Navigator.of(context).pop();
        return;
      }
      widget.room!
          .sendFileOnWebEvent(
        file,
        thumbnail: thumbnail,
      )
          .catchError((e) {
        TwakeSnackBar.show(context, (e as Object).toLocalizedString(context));
        return null;
      });
    }
    Navigator.of(context, rootNavigator: false).pop();

    return;
  }

  void send() {
    if (textEditingController.text.isEmpty) {
      sendWithoutCaption();
    } else {
      sendMediaWithCaption();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SendFileDialogView(this);
  }
}
