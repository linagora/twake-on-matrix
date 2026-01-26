import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/send_file_dialog/generate_thumbnails_media_state.dart';
import 'package:fluffychat/domain/usecase/generate_thumbnails_media_interactor.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog_view.dart';
import 'package:fluffychat/presentation/list_notifier.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/presentation/enum/chat/send_media_with_caption_status_enum.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class SendMediaDialogResult with EquatableMixin {
  final SendMediaWithCaptionStatus status;
  final String? caption;

  SendMediaDialogResult({
    required this.status,
    this.caption,
  });

  @override
  List<Object?> get props => [status, caption];
}

class SendFileDialog extends StatefulWidget {
  final Room? room;
  final List<MatrixFile> files;
  final String? pendingText;
  final Event? inReplyTo;

  const SendFileDialog({
    this.room,
    required this.files,
    super.key,
    this.pendingText,
    this.inReplyTo,
  });

  @override
  SendFileDialogController createState() => SendFileDialogController();
}

class SendFileDialogController extends State<SendFileDialog> {
  final uploadManager = getIt.get<UploadManager>();

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

  StreamSubscription? _thumbnailsForMediaSubscription;

  @override
  void initState() {
    super.initState();
    filesNotifier = ListNotifier(widget.files);
    isSendMediaWithCaption = _isShowSendMediaDialog(
      filesNotifier.value,
      widget.room,
    );
    textEditingController.text = widget.pendingText ?? '';
    requestFocusCaptions();
    loadThumbnailsForMedia(filesNotifier.value);
  }

  @override
  void dispose() {
    textEditingController.dispose();
    focusSuggestionController.dispose();
    captionsFocusNode.dispose();
    filesNotifier.dispose();
    maxMediaSizeNotifier.dispose();
    haveErrorFilesNotifier.dispose();
    _thumbnailsForMediaSubscription?.cancel();
    super.dispose();
  }

  void updateHaveErrorFilesNotifier() {
    haveErrorFilesNotifier.value = filesNotifier.value.any(
      (file) => file.size > maxMediaSizeNotifier.value,
    );
  }

  void loadThumbnailsForMedia(List<MatrixFile> files) {
    if (widget.room == null) {
      return;
    }
    _thumbnailsForMediaSubscription = generateThumbnailsMediaInteractor
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
      Navigator.of(context).pop(
        SendMediaDialogResult(
          status: SendMediaWithCaptionStatus.emptyRoom,
          caption: textEditingController.text,
        ),
      );
      return;
    }
    if (filesNotifier.value.isEmpty) {
      return;
    }
    uploadManager
        .uploadFilesWeb(
          room: widget.room!,
          files: [filesNotifier.value.first],
          caption: textEditingController.text,
          inReplyTo: widget.inReplyTo,
        )
        .then((_) => PaintingBinding.instance.imageCache.clear());
    Navigator.of(context).pop(
      SendMediaDialogResult(
        status: SendMediaWithCaptionStatus.done,
      ),
    );
  }

  List<MatrixFile> getFilesNotError() {
    return filesNotifier.value
        .where((file) => !file.isFileHaveError(maxMediaSizeNotifier.value))
        .toList();
  }

  void sendFilesWithCaption() async {
    if (widget.room == null) {
      Logs().e("sendFilesWithCaption:: room is null");
      Navigator.of(context).pop(
        SendMediaDialogResult(
          status: SendMediaWithCaptionStatus.emptyRoom,
          caption: textEditingController.text,
        ),
      );
      return;
    }
    uploadManager
        .uploadFilesWeb(
          room: widget.room!,
          files: getFilesNotError(),
          caption: textEditingController.text,
          thumbnails: thumbnails,
          inReplyTo: widget.inReplyTo,
        )
        .then((_) => PaintingBinding.instance.imageCache.clear());
    Navigator.of(context).pop(
      SendMediaDialogResult(
        status: SendMediaWithCaptionStatus.done,
      ),
    );
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
