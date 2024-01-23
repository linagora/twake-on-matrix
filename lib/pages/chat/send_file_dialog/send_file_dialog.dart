import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/send_files_on_web_with_caption_interactor.dart';
import 'package:fluffychat/domain/usecase/send_media_on_web_with_caption_interactor.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/presentation/list_notifier.dart';
import 'send_file_dialog_view.dart';
import 'package:fluffychat/presentation/enum/chat/send_media_with_caption_status_enum.dart';
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

  final FocusNode captionsFocusNode = FocusNode();

  final ValueKey sendFileDialogTypeAheadKey =
      const ValueKey('sendFileDialogTypeAhead');

  bool isSendMediaWithCaption = true;

  ListNotifier<MatrixFile> filesNotifier = ListNotifier([]);

  Map<MatrixFile, MatrixImageFile?> thumbnails = {};

  @override
  void initState() {
    super.initState();
    filesNotifier = ListNotifier(widget.files);
    isSendMediaWithCaption = _isShowSendMediaDialog(
      filesNotifier.value,
      widget.room,
    );
    requestFocusCaptions();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadThumbnailsForMedia();
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  Future<void> loadThumbnailsForMedia() async {
    if (widget.room == null) {
      return;
    }
    final results = await Future.wait<MatrixImageFile?>(
      filesNotifier.value.map((file) {
        if (file is MatrixImageFile) {
          return widget.room!.generateThumbnail(file);
        } else if (file is MatrixVideoFile) {
          return widget.room!.generateVideoThumbnail(file);
        }
        return Future.value(null);
      }),
    );
    for (int i = 0; i < filesNotifier.value.length; i++) {
      thumbnails[filesNotifier.value[i]] = results[i];
    }
    filesNotifier.notify();
  }

  void requestFocusCaptions() {
    captionsFocusNode.requestFocus();
  }

  void sendMediaWithCaption() {
    if (widget.room == null) {
      Logs().e("sendMediaWithCaption:: room is null");
      Navigator.of(context).pop(SendMediaWithCaptionStatus.error);
      return;
    }
    if (filesNotifier.value.isEmpty) {
      return;
    }
    sendMediaOnWebWithCaptionInteractor.execute(
      room: widget.room!,
      media: filesNotifier.value.first,
      caption: textEditingController.text,
    );
    Navigator.of(context).pop(SendMediaWithCaptionStatus.done);
  }

  void sendFilesWithCaption() {
    if (widget.room == null) {
      Logs().e("sendFilesWithCaption:: room is null");
      Navigator.of(context).pop(SendMediaWithCaptionStatus.error);
      return;
    }
    sendFilesOnWebWithCaptionInteractor.execute(
      room: widget.room!,
      files: filesNotifier.value,
      caption: textEditingController.text,
    );
    Navigator.of(context).pop(SendMediaWithCaptionStatus.done);
  }

  void send() {
    if (_isShowSendMediaDialog(filesNotifier.value, widget.room)) {
      sendMediaWithCaption();
    } else {
      sendFilesWithCaption();
    }
  }

  bool _isShowSendMediaDialog(List<MatrixFile> matrixFilesList, Room? room) =>
      matrixFilesList.length == 1 &&
      matrixFilesList.first is MatrixImageFile &&
      room != null;

  void onRemoveFile(MatrixFile matrixFile) {
    filesNotifier.remove(matrixFile);
    if (filesNotifier.value.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SendFileDialogView(this);
  }
}
