import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item_style.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/widgets/file_widget/circular_loading_download_widget.dart';
import 'package:fluffychat/widgets/file_widget/message_file_tile_style.dart';
import 'package:flutter/material.dart';

class ChatDetailsFileRowDownloadingWrapper extends StatelessWidget {
  final Widget child;
  final String? mimeType;
  final String? fileType;
  final ValueNotifier<DownloadPresentationState> downloadFileStateNotifier;

  const ChatDetailsFileRowDownloadingWrapper({
    super.key,
    required this.child,
    required this.mimeType,
    required this.fileType,
    required this.downloadFileStateNotifier,
  });

  final style = const MessageFileTileStyle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: ChatDetailsFileTileStyle.wrapperLeftPadding,
        ),
        ValueListenableBuilder(
          valueListenable: downloadFileStateNotifier,
          builder: (context, downloadFileState, child) {
            double? downloadProgress;
            if (downloadFileState is DownloadingPresentationState) {
              if (downloadFileState.total == null ||
                  downloadFileState.receive == null) {
                downloadProgress = null;
              } else {
                downloadProgress =
                    downloadFileState.receive! / downloadFileState.total!;
              }
            } else if (downloadFileState is NotDownloadPresentationState) {
              downloadProgress = 0;
            }
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  margin: style.marginDownloadIcon,
                  width: style.iconSize,
                  height: style.iconSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (downloadProgress != 0)
                  SizedBox(
                    width: style.circularProgressLoadingSize,
                    height: style.circularProgressLoadingSize,
                    child: CircularLoadingDownloadWidget(
                      style: style,
                      downloadProgress: downloadProgress,
                    ),
                  ),
                Container(
                  width: style.downloadIconSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    downloadProgress == 0 ? Icons.arrow_downward : Icons.close,
                    key: ValueKey(downloadProgress),
                    color: Theme.of(context).colorScheme.surface,
                    size: style.downloadIconSize,
                  ),
                ),
              ],
            );
          },
        ),
        ChatDetailsFileTileStyle().paddingRightIcon,
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
