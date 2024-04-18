import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item_style.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_row_downloading_wrapper.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ChatDetailsDownloadingFileTile extends StatelessWidget {
  const ChatDetailsDownloadingFileTile({
    super.key,
    required this.onTap,
    required this.filename,
    required this.mimeType,
    required this.fileType,
    required this.sizeString,
    required this.downloadFileStateNotifier,
  });

  final GestureTapCallback onTap;
  final String filename;
  final String? mimeType;
  final String? fileType;
  final String? sizeString;
  final ValueNotifier<DownloadPresentationState> downloadFileStateNotifier;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: LinagoraSysColors.material().surfaceVariant,
      onTap: onTap,
      child: ChatDetailsFileRowDownloadingWrapper(
        mimeType: mimeType,
        fileType: fileType,
        downloadFileStateNotifier: downloadFileStateNotifier,
        child: Container(
          height: ChatDetailsFileTileStyle.tileHeight,
          padding: ChatDetailsFileTileStyle.bodyPadding,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: ChatDetailsFileTileStyle.dividerHeight,
                color: ChatDetailsFileTileStyle.dividerColor(context),
              ),
            ),
          ),
          child: Padding(
            padding: ChatDetailsFileTileStyle.bodyChildPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: ChatDetailsFileTileStyle.downloadFilenameMaxLines,
                  text: TextSpan(
                    text: filename,
                    style: ChatDetailsFileTileStyle.downloadFileTextStyle(
                      context,
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (sizeString != null)
                  Expanded(
                    child: TextInformationOfFile(
                      value: sizeString!,
                      style: ChatDetailsFileTileStyle().textInformationStyle(
                        context,
                      ),
                      downloadFileStateNotifier: downloadFileStateNotifier,
                    ),
                  )
                else
                  SizedBox(
                    height: ChatDetailsFileTileStyle
                        .downloadingTileBottomPlaceholder,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
