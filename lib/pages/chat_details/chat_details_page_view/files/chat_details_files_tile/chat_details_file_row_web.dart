import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item_style.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_row_wrapper.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ChatDetailsFileTileRowWeb extends StatelessWidget {
  const ChatDetailsFileTileRowWeb({
    super.key,
    required this.mimeType,
    required this.filename,
    required this.sentDate,
    required this.fileType,
    required this.sizeString,
    required this.onTap,
    required this.isDownloaded,
  });

  final GestureTapCallback onTap;
  final TwakeMimeType mimeType;
  final String filename;
  final String? sizeString;
  final String? fileType;
  final DateTime sentDate;
  final bool isDownloaded;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: LinagoraSysColors.material().surfaceVariant,
      onTap: onTap,
      child: ChatDetailsFileRowWrapper(
        mimeType: mimeType,
        fileType: fileType,
        child: Container(
          padding: ChatDetailsFileTileStyle.bodyPaddingWeb,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: ChatDetailsFileTileStyle.dividerHeight,
                color: ChatDetailsFileTileStyle.dividerColor(context),
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      filename,
                      style: ChatDetailsFileTileStyle.downloadFileTextStyle(
                        context,
                      ),
                      maxLines:
                          ChatDetailsFileTileStyle.downloadFilenameMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: ChatDetailsFileTileStyle.trailingPadding,
                    child: Text(
                      sentDate.localizedTimeShort(context),
                      style: ChatDetailsFileTileStyle()
                          .textInformationStyle(context),
                    ),
                  ),
                ],
              ),
              if (!isDownloaded)
                Row(
                  children: [
                    if (sizeString != null)
                      Text(
                        sizeString!,
                        style:
                            ChatDetailsFileTileStyle.downloadSizeFileTextStyle(
                          context,
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.download_outlined,
                      color: const FileTileWidgetStyle().fileInfoColor,
                    ),
                  ],
                )
              else
                const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
