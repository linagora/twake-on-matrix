import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/send_file_dialog/generate_thumbnails_media_state.dart';
import 'package:fluffychat/domain/usecase/generate_thumbnails_media_interactor.dart';
import 'package:fluffychat/domain/usecase/send_files_on_web_with_caption_interactor.dart';
import 'package:fluffychat/domain/usecase/send_media_on_web_with_caption_interactor.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog_view.dart';
import 'package:fluffychat/presentation/list_notifier.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/presentation/enum/chat/send_media_with_caption_status_enum.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class SendFileDialog extends StatefulWidget {
  final Room? room;
  final List<MatrixFile> files;

  const SendFileDialog({
    this.room,
    required this.files,
    super.key,
  });

  @override
  SendFileDialogController createState() => SendFileDialogController();
}

class SendFileDialogController extends State<SendFileDialog> {
  final sendMediaOnWebWithCaptionInteractor =
      getIt.get<SendMediaOnWebWithCaptionInteractor>();

  final sendFilesOnWebWithCaptionInteractor =
      getIt.get<SendFilesOnWebWithCaptionInteractor>();

  final generateThumbnailsMediaInteractor =
      getIt.get<GenerateThumbnailsMediaInteractor>();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadThumbnailsForMedia(filesNotifier.value);
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    focusSuggestionController.dispose();
    captionsFocusNode.dispose();
    filesNotifier.dispose();
    maxMediaSizeNotifier.dispose();
    haveErrorFilesNotifier.dispose();
    super.dispose();
  }

  void updateHaveErrorFilesNotifier() {
    haveErrorFilesNotifier.value = filesNotifier.value.any(
      (file) => file.size > maxMediaSizeNotifier.value,
    );
  }

  Future<void> loadThumbnailsForMedia(List<MatrixFile> files) async {
    if (widget.room == null) {
      return;
    }
    generateThumbnailsMediaInteractor
        .execute(
      room: widget.room!,
      files: files,
    )
        .listen((event) {
      event.fold(
        (left) {
          Logs().e("loadThumbnailsForMedia:: $left");
        },
        (right) async {
          if (right is GenerateThumbnailsMediaSuccess) {
            thumbnails[right.file] = right.thumbnail;
            filesNotifier.notify();
          } else if (right is ConvertReadStreamToBytesSuccess) {
            filesNotifier.update(right.oldFile, right.newFile);
          } else if (right is GenerateThumbnailsMediaInitial) {
            maxMediaSizeNotifier.value = right.maxUploadFileSize.toDouble();
            updateHaveErrorFilesNotifier();
          }
        },
      );
    });
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
