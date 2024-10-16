import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/file_widget/download_file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/downloading_file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/message_file_tile_style.dart';
import 'package:fluffychat/widgets/mixins/download_file_on_mobile_mixin.dart';
import 'package:fluffychat/widgets/mixins/handle_download_and_preview_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class MessageDownloadContent extends StatefulWidget {
  final Event event;

  final String? highlightText;

  const MessageDownloadContent(
    this.event, {
    super.key,
    this.highlightText,
  });

  @override
  State<MessageDownloadContent> createState() => _MessageDownloadContentState();
}

class _MessageDownloadContentState extends State<MessageDownloadContent>
    with
        HandleDownloadAndPreviewFileMixin,
        DownloadFileOnMobileMixin<MessageDownloadContent> {
  @override
  Event get event => widget.event;

  @override
  Widget build(BuildContext context) {
    final filename = widget.event.filename;
    final filetype = widget.event.fileType;
    final sizeString = widget.event.sizeString;
    return ValueListenableBuilder(
      valueListenable: downloadFileStateNotifier,
      builder: (context, DownloadPresentationState state, child) {
        if (state is DownloadedPresentationState) {
          return InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: () async {
              handleDownloadFileForPreviewSuccess(
                filePath: state.filePath,
                mimeType: widget.event.mimeType,
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
        } else if (state is DownloadingPresentationState ||
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
        }

        return InkWell(
          onTap: () => onDownloadFileTap(),
          child: DownloadingFileTileWidget(
            mimeType: widget.event.mimeType,
            fileType: filetype,
            filename: filename,
            highlightText: widget.highlightText,
            sizeString: sizeString,
            downloadFileStateNotifier: downloadFileStateNotifier,
            ownMessage: event.isOwnMessage,
            style: const MessageFileTileStyle(),
          ),
        );
      },
    );
  }
}
