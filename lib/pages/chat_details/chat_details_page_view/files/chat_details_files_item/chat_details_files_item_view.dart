import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_file_download_tile.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_file_downloaded_tile.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_file_downloading_tile.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatDetailsFilesView extends StatelessWidget {
  const ChatDetailsFilesView({
    super.key,
    required this.controller,
  });

  final ChatDetailsFileItemController controller;

  @override
  Widget build(BuildContext context) {
    final filename = controller.event.filename;
    final filetype = controller.event.fileType;
    final sizeString = controller.event.sizeString;

    return ValueListenableBuilder(
      valueListenable: controller.downloadFileStateNotifier,
      builder: (context, DownloadPresentationState state, child) {
        if (state is DownloadingPresentationState) {
          return ChatDetailsDownloadingFileTile(
            mimeType: controller.event.mimeType,
            fileType: filetype,
            filename: filename,
            sizeString: sizeString,
            downloadFileStateNotifier: controller.downloadFileStateNotifier,
            onTap: () {
              controller.downloadFileStateNotifier.value =
                  const NotDownloadPresentationState();
              controller.downloadManager
                  .cancelDownload(controller.event.eventId);
            },
          );
        } else if (state is DownloadedPresentationState) {
          return ChatDetailsDownloadedFileTile(
            onTap: () {
              controller.handleDownloadFileForPreviewSuccess(
                filePath: state.filePath,
                mimeType: controller.event.mimeType,
              );
            },
            trailingIcon: Icons.folder_outlined,
            iconColor: LinagoraSysColors.material().primary,
            filename: filename,
            mimeType: controller.event.mimeType,
            fileType: filetype,
          );
        }

        return ChatDetailsDownloadFileTile(
          onTap: () => controller.onDownloadFileTap(),
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
