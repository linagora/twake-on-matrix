import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item_web/chat_details_files_item_web.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_file_row.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/file_widget/download_file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/message_file_tile_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatDetailsFilesViewWeb extends StatelessWidget {
  const ChatDetailsFilesViewWeb({
    super.key,
    required this.controller,
  });

  final ChatDetailsFileItemWebState controller;

  @override
  Widget build(BuildContext context) {
    final filename = controller.event.filename;
    final filetype = controller.event.fileType;
    final sizeString = controller.event.sizeString;

    return ValueListenableBuilder(
      valueListenable: controller.downloadFileStateNotifier,
      builder: (context, DownloadPresentationState state, child) {
        if (state is DownloadingPresentationState) {
          return DownloadFileTileWidget(
            mimeType: controller.event.mimeType,
            fileType: filetype,
            filename: filename,
            sizeString: sizeString,
            style: const MessageFileTileStyle(),
            downloadFileStateNotifier: controller.downloadFileStateNotifier,
            onCancelDownload: () {
              controller.downloadFileStateNotifier.value =
                  const NotDownloadPresentationState();
              controller.downloadManager
                  .cancelDownload(controller.event.eventId);
            },
          );
        }

        return ChatDetailsDownloadFileTileWidget(
          onTap: () {
            if (state is FileWebDownloadedPresentationState) {
              controller.handlePreviewWeb(
                event: controller.event,
                context: context,
              );
            } else {
              controller.downloadFileStateNotifier.value =
                  const DownloadingPresentationState();
              controller.downloadManager.download(
                event: controller.event,
              );
              controller.trySetupDownloadingStreamSubcription();
            }
          },
          mimeType: controller.event.mimeType,
          fileType: filetype,
          filename: filename,
          sizeString: sizeString,
          sentDate: controller.event.originServerTs,
          trailingIcon: Icons.download_outlined,
          iconColor: LinagoraSysColors.material().tertiary,
        );
      },
    );
  }
}
