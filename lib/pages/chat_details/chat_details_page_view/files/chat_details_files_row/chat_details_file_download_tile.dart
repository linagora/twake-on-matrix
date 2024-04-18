import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item_style.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_file_row_body.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_row_wrapper.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ChatDetailsDownloadFileTile extends StatelessWidget {
  const ChatDetailsDownloadFileTile({
    super.key,
    required this.onTap,
    required this.trailingIcon,
    required this.iconColor,
    required this.filename,
    required this.mimeType,
    required this.fileType,
    required this.sizeString,
    required this.sentDate,
  });

  final GestureTapCallback onTap;
  final IconData trailingIcon;
  final Color iconColor;
  final String filename;
  final String? mimeType;
  final String? fileType;
  final String? sizeString;
  final DateTime sentDate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: LinagoraSysColors.material().surfaceVariant,
      onTap: onTap,
      child: ChatDetailsFileRowWrapper(
        mimeType: mimeType,
        fileType: fileType,
        child: Column(
          children: [
            ChatDetailsFileRowBody(
              trailingIcon: trailingIcon,
              iconColor: iconColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filename,
                    style:
                        ChatDetailsFileTileStyle.downloadFileTextStyle(context),
                    maxLines: ChatDetailsFileTileStyle.downloadFilenameMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Flexible(
                    child: Row(
                      children: [
                        if (sizeString != null) ...[
                          Text(
                            sizeString!,
                            style: ChatDetailsFileTileStyle()
                                .textInformationStyle(context),
                          ),
                          Text(
                            " - ",
                            style: ChatDetailsFileTileStyle()
                                .textInformationStyle(context),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            sentDate.localizedTime(context),
                            style: ChatDetailsFileTileStyle()
                                .textInformationStyle(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
