import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item_style.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_file_row_body.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_row_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ChatDetailsDownloadedFileTile extends StatelessWidget {
  const ChatDetailsDownloadedFileTile({
    super.key,
    required this.onTap,
    required this.trailingIcon,
    required this.iconColor,
    required this.filename,
    required this.mimeType,
    required this.fileType,
  });

  final GestureTapCallback onTap;
  final IconData trailingIcon;
  final Color iconColor;
  final String filename;
  final String? mimeType;
  final String? fileType;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: LinagoraSysColors.material().surfaceVariant,
      onTap: onTap,
      child: ChatDetailsFileRowWrapper(
        mimeType: mimeType,
        fileType: fileType,
        child: ChatDetailsFileRowBody(
          trailingIcon: trailingIcon,
          iconColor: iconColor,
          child: Text(
            filename,
            style: ChatDetailsFileTileStyle.downloadedFileTextStyle(context),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
