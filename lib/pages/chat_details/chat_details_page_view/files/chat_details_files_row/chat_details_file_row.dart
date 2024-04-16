import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_row/chat_details_file_row_style.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/widgets/file_widget/base_file_tile_widget.dart';
import 'package:flutter/material.dart';

class ChatDetailsFileTileRow extends BaseFileTileWidget {
  ChatDetailsFileTileRow({
    super.key,
    required super.mimeType,
    required super.filename,
    required DateTime sentDate,
    super.style,
    super.imageBytes,
    super.fileTileIcon,
    super.fileType,
    super.highlightText,
    super.sizeString,
  }) : super(
          subTitle: (context) => Row(
            children: [
              if (sizeString != null) ...[
                Text(
                  sizeString,
                  style: ChatDetailsFileRowStyle.textInformationStyle(context),
                ),
                Text(
                  " - ",
                  style: ChatDetailsFileRowStyle.textInformationStyle(context),
                ),
              ],
              Flexible(
                child: Text(
                  sentDate.localizedTime(context),
                  style: ChatDetailsFileRowStyle.textInformationStyle(context),
                ),
              ),
            ],
          ),
        );
}
