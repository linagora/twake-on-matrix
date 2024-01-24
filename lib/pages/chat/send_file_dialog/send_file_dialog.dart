import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/send_files_on_web_with_caption_interactor.dart';
import 'package:fluffychat/domain/usecase/send_media_on_web_with_caption_interactor.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/presentation/list_notifier.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
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

  ValueNotifier<double> maxMediaSizeNotifier = ValueNotifier(double.infinity);

  ValueNotifier<bool> haveErrorFilesNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    filesNotifier = ListNotifier(widget.files);
    isSendMediaWithCaption = _isShowSendMediaDialog(
      filesNotifier.value,
      widget.room,
    );
    requestFocusCaptions();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await loadMaxMediaSize();
      await loadThumbnailsForMedia();
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  Future<void> loadMaxMediaSize() async {
    if (widget.room == null) {
      return;
    }
    final mediaConfig = await widget.room?.client.getConfig();
    maxMediaSizeNotifier.value =
        mediaConfig?.mUploadSize?.toDouble() ?? double.infinity;
    updateHaveErrorFilesNotifier();
  }

  void updateHaveErrorFilesNotifier() {
    haveErrorFilesNotifier.value = filesNotifier.value.any(
      (file) => file.size > maxMediaSizeNotifier.value,
    );
  }

  Future<void> loadThumbnailsForMedia() async {
    if (widget.room == null) {
      return;
    }
    List<MatrixFile> files = await getFilesNotError();
    files = await convertFilesToBytes(files);
    final filesHaveThumbnail =
        files.where((file) => file.isFileHaveThumbnail).toList();
    final results = await Future.wait<MatrixImageFile?>(
      filesHaveThumbnail.map((file) async {
        if (file is MatrixImageFile) {
          return widget.room!.generateThumbnail(file);
        } else if (file is MatrixVideoFile) {
          return widget.room!.generateVideoThumbnail(file);
        }
        return Future.value(null);
      }),
    );
    updateThumbnailsForMediaFiles(filesHaveThumbnail, results);
  }

  void updateThumbnailsForMediaFiles(
    List<MatrixFile> filesHaveThumbnail,
    List<MatrixImageFile?> results,
  ) {
    for (int i = 0; i < filesHaveThumbnail.length; i++) {
      thumbnails[filesHaveThumbnail[i]] = results[i];
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

  Future<List<MatrixFile>> getFilesNotError() async {
    return filesNotifier.value
        .where((file) => !file.isFileHaveError(maxMediaSizeNotifier.value))
        .toList();
  }

  Future<List<MatrixFile>> convertFilesToBytes(List<MatrixFile> files) async {
    final results = await Future.wait(
      files
          .map(
            (file) => file.convertReadStreamToBytes(),
          )
          .toList(),
    );
    for (int i = 0; i < files.length; i++) {
      filesNotifier.update(files[i], results[i]);
    }
    return results;
  }

  void sendFilesWithCaption() async {
    if (widget.room == null) {
      Logs().e("sendFilesWithCaption:: room is null");
      Navigator.of(context).pop(SendMediaWithCaptionStatus.error);
      return;
    }

    sendFilesOnWebWithCaptionInteractor.execute(
      room: widget.room!,
      files: await getFilesNotError(),
      caption: textEditingController.text,
      thumbnails: thumbnails,
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
    updateHaveErrorFilesNotifier();
    if (filesNotifier.value.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SendFileDialogView(this);
  }
}
