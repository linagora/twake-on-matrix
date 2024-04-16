import 'dart:async';

import 'package:dartz/dartz.dart' hide State, OpenFile;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item_view.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/manager/download_manager/download_manager.dart';
import 'package:fluffychat/widgets/mixins/handle_download_and_preview_file_mixin.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatDetailsFileItem extends StatefulWidget {
  const ChatDetailsFileItem({super.key, required this.event});

  final Event event;

  @override
  State<ChatDetailsFileItem> createState() => ChatDetailsFileItemState();
}

class ChatDetailsFileItemState extends State<ChatDetailsFileItem>
    with HandleDownloadAndPreviewFileMixin {
  final downloadManager = getIt.get<DownloadManager>();

  final downloadFileStateNotifier = ValueNotifier<DownloadPresentationState>(
    const NotDownloadPresentationState(),
  );

  StreamSubscription<Either<Failure, Success>>? streamSubscription;

  Event get event => widget.event;

  @override
  void initState() {
    super.initState();
    trySetupDownloadingStreamSubcription();
    if (streamSubscription != null) {
      downloadFileStateNotifier.value = const DownloadingPresentationState();
    }
  }

  void trySetupDownloadingStreamSubcription() {
    streamSubscription = downloadManager
        .getDownloadStateStream(widget.event.eventId)
        ?.listen(setupDownloadingProcess);
  }

  void setupDownloadingProcess(Either<Failure, Success> event) {
    event.fold(
      (failure) {
        Logs().e('ChatDetailsFileItem::onDownloadingProcess(): $failure');
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
    return ChatDetailsFilesView(controller: this);
  }
}
