import 'dart:async';

import 'package:dartz/dartz.dart' hide State, OpenFile;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/manager/download_manager/download_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/file_widget/download_file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/message_file_tile_style.dart';
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
    with HandleDownloadAndPreviewFileMixin {
  final downloadManager = getIt.get<DownloadManager>();

  final downloadFileStateNotifier = ValueNotifier<DownloadPresentationState>(
    const NotDownloadPresentationState(),
  );

  StreamSubscription<Either<Failure, Success>>? streamSubscription;

  @override
  void initState() {
    super.initState();
    _trySetupDownloadingStreamSubcription();
    if (streamSubscription != null) {
      downloadFileStateNotifier.value = const DownloadingPresentationState();
    }
  }

  void _trySetupDownloadingStreamSubcription() {
    streamSubscription = downloadManager
        .getDownloadStateStream(widget.event.eventId)
        ?.listen(setupDownloadingProcess);
  }

  void setupDownloadingProcess(Either<Failure, Success> event) {
    event.fold(
      (failure) {
        Logs().e('MessageDownloadContent::onDownloadingProcess(): $failure');
        downloadFileStateNotifier.value = const NotDownloadPresentationState();
      },
      (success) {
        if (success is DownloadingFileState) {
          if (success.total != 0) {
            downloadFileStateNotifier.value = DownloadingPresentationState(
              receive: success.receive,
              total: success.total,
            );
          }
        } else if (success is DownloadMatrixFileSuccessState) {
          _handleDownloadMatrixFileSuccessState(success);
        }
      },
    );
  }

  void _handleDownloadMatrixFileSuccessState(
    DownloadMatrixFileSuccessState success,
  ) {
    streamSubscription?.cancel();
    if (mounted) {
      downloadFileStateNotifier.value = FileWebDownloadedPresentationState(
        matrixFile: success.matrixFile,
      );
      handlePreviewWeb(event: widget.event, context: context);
      return;
    }

    if (TwakeApp.routerKey.currentContext != null) {
      handlePreviewWeb(
        event: widget.event,
        context: TwakeApp.routerKey.currentContext!,
      );
    }
  }

  @override
  void dispose() {
    downloadFileStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filename = widget.event.filename;
    final filetype = widget.event.fileType;
    final sizeString = widget.event.sizeString;
    return ValueListenableBuilder(
      valueListenable: downloadFileStateNotifier,
      builder: (context, DownloadPresentationState state, child) {
        if (state is DownloadingPresentationState) {
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
            _trySetupDownloadingStreamSubcription();
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
