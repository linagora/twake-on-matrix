import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_file_row.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item_style.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/file_widget/download_file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/message_file_tile_style.dart';
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

        return InkWell(
          hoverColor: LinagoraSysColors.material().surfaceVariant,
          onTap: () {
            if (state is DownloadedPresentationState) {
              controller.handleDownloadFileForPreviewSuccess(
                filePath: state.filePath,
                mimeType: controller.event.mimeType,
              );
            } else {
              controller.onDownloadFileTap();
            }
          },
          child: Padding(
            padding: ChatDetailsFileTileStyle().paddingFileTileAll,
            child: ChatDetailsFileTileRow(
              mimeType: controller.event.mimeType,
              fileType: filetype,
              filename: filename,
              sizeString: sizeString,
              style: ChatDetailsFileTileStyle(),
              sentDate: controller.event.originServerTs,
            ),
          ),
        );
      },
    );
  }
}
