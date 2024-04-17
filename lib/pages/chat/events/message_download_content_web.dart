import 'dart:async';

import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
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
    Key? key,
    this.highlightText,
  }) : super(key: key);

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
  Future<void> get handlePreview => handlePreviewWeb(
        event: widget.event,
        context: TwakeApp.routerKey.currentContext!,
      );

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
            hasError: state is DownloadErrorPresentationState,
          );
        } else if (state is FileWebDownloadedPresentationState) {
          return InkWell(
            onTap: () {
              handlePreviewWeb(
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
            ),
          );
        }

        return InkWell(
          onTap: () {
            downloadFileStateNotifier.value =
                const DownloadingPresentationState();
            downloadManager.download(
              event: widget.event,
            );
            trySetupDownloadingStreamSubcription();
          },
          child: FileTileWidget(
            mimeType: widget.event.mimeType,
            fileType: filetype,
            filename: filename,
            highlightText: widget.highlightText,
            sizeString: sizeString,
            style: const MessageFileTileStyle(),
          ),
        );
      },
    );
  }
}
