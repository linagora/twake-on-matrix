import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/file_widget/download_file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/message_file_tile_style.dart';
import 'package:fluffychat/widgets/mixins/download_file_on_web_mixin.dart';
import 'package:fluffychat/widgets/mixins/handle_download_and_preview_file_mixin.dart';
import 'package:fluffychat/widgets/twake_app.dart';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class MessageDownloadContentWeb extends StatefulWidget {
  const MessageDownloadContentWeb(
    this.event, {
    super.key,
    this.highlightText,
  });

  final Event event;

  final String? highlightText;

  @override
  State<StatefulWidget> createState() => _MessageDownloadContentWebState();
}

class _MessageDownloadContentWebState extends State<MessageDownloadContentWeb>
    with
        HandleDownloadAndPreviewFileMixin,
        DownloadFileOnWebMixin<MessageDownloadContentWeb> {
  @override
  Event get event => widget.event;

  @override
  void handleDownloadMatrixFileSuccessDone({
    required DownloadMatrixFileSuccessState success,
  }) {
    streamSubscription?.cancel();
    if (mounted) {
      downloadFileStateNotifier.value = FileWebDownloadedPresentationState(
        matrixFile: success.matrixFile,
      );
      downloadFileStateNotifier.dispose();
      handlePreviewWeb(
        event: widget.event,
        matrixFile: success.matrixFile,
        context: context,
      );
      return;
    }

    if (TwakeApp.routerKey.currentContext != null) {
      handlePreviewWeb(
        matrixFile: success.matrixFile,
        event: widget.event,
        context: TwakeApp.routerKey.currentContext!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filename = widget.event.filename;
    final filetype = widget.event.fileType;
    final sizeString = widget.event.sizeString;
    return ValueListenableBuilder(
      valueListenable: downloadFileStateNotifier,
      builder: (context, DownloadPresentationState state, child) {
        if (state is DownloadingPresentationState ||
            state is DownloadErrorPresentationState) {
          return DownloadFileTileWidget(
            mimeType: widget.event.mimeType,
            fileType: filetype,
            filename: filename,
            highlightText: widget.highlightText,
            sizeString: sizeString,
            style: const MessageFileTileStyle(),
            downloadFileStateNotifier: downloadFileStateNotifier,
            onCancelDownload: () {
              downloadFileStateNotifier.value =
                  const NotDownloadPresentationState();
              downloadManager.cancelDownload(widget.event.eventId);
            },
            ownMessage: event.isOwnMessage,
            hasError: state is DownloadErrorPresentationState,
          );
        } else if (state is FileWebDownloadedPresentationState) {
          return InkWell(
            onTap: () {
              handlePreviewWeb(
                matrixFile: state.matrixFile,
                event: widget.event,
                context: context,
              );
            },
            child: FileTileWidget(
              mimeType: widget.event.mimeType,
              fileType: filetype,
              filename: filename,
              highlightText: widget.highlightText,
              sizeString: sizeString,
              style: const MessageFileTileStyle(),
              ownMessage: event.isOwnMessage,
            ),
          );
        }

        return InkWell(
          onTap: () => onDownloadFileTap(),
          child: FileTileWidget(
            mimeType: widget.event.mimeType,
            fileType: filetype,
            filename: filename,
            highlightText: widget.highlightText,
            sizeString: sizeString,
            style: const MessageFileTileStyle(),
            ownMessage: event.isOwnMessage,
          ),
        );
      },
    );
  }
}
