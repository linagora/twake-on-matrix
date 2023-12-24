import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/send_files_on_web_with_caption_interactor.dart';
import 'package:fluffychat/domain/usecase/send_media_on_web_with_caption_interactor.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/send_file_dialog_view.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

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
  final sendMediaOnWebWithCaptionInteractor =
      getIt.get<SendMediaOnWebWithCaptionInteractor>();

  final sendFilesOnWebWithCaptionInteractor =
      getIt.get<SendFilesOnWebWithCaptionInteractor>();

  final focusSuggestionController = FocusSuggestionController();

  final TextEditingController textEditingController = TextEditingController();

  bool isSendMediaWithCaption = true;

  List<MatrixFile> get files => widget.files;

  @override
  void initState() {
    super.initState();
    isSendMediaWithCaption = _isShowSendMediaDialog(widget.files, widget.room);
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

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
    Navigator.of(context).pop(true);
  }

  void sendFilesWithCaption() {
    if (widget.room == null) {
      Logs().e("sendFilesWithCaption:: room is null");
      Navigator.of(context).pop();
      return;
    }
    sendFilesOnWebWithCaptionInteractor.execute(
      room: widget.room!,
      files: widget.files,
      caption: textEditingController.text,
    );
    Navigator.of(context).pop(true);
  }

  void send() {
    if (_isShowSendMediaDialog(widget.files, widget.room)) {
      sendMediaWithCaption();
    } else {
      sendFilesWithCaption();
    }
  }

  bool _isShowSendMediaDialog(List<MatrixFile> matrixFilesList, Room? room) =>
      matrixFilesList.length == 1 &&
      matrixFilesList.first is MatrixImageFile &&
      room != null;

  @override
  Widget build(BuildContext context) {
    return SendFileDialogView(this);
  }
}
