import 'dart:typed_data';

import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_file_row_style.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatDetailsFileTileRow extends StatelessWidget {
  const ChatDetailsFileTileRow({
    super.key,
    required this.mimeType,
    required this.filename,
    required this.sentDate,
    this.style = const FileTileWidgetStyle(),
    this.imageBytes,
    this.fileTileIcon,
    this.fileType,
    this.highlightText,
    this.sizeString,
  });

  final FileTileWidgetStyle style;
  final Uint8List? imageBytes;
  final String? fileTileIcon;
  final TwakeMimeType? mimeType;
  final String? fileType;
  final String filename;
  final String? highlightText;
  final String? sizeString;
  final DateTime sentDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: style.crossAxisAlignment,
      children: [
        if (imageBytes != null)
          Padding(
            padding: style.imagePadding,
            child: ClipRRect(
              borderRadius: style.borderRadius,
              child: Image.memory(
                imageBytes!,
                width: style.imageSize,
                height: style.imageSize,
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          SvgPicture.asset(
            fileTileIcon ?? mimeType.getIcon(fileType: fileType),
            width: style.iconSize,
            height: style.iconSize,
          ),
        style.paddingRightIcon,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: ChatDetailsFileRow.textTopMargin),
              FileNameText(
                filename: filename,
                highlightText: highlightText,
                style: style,
              ),
              Row(
                children: [
                  if (sizeString != null) ...[
                    Text(
                      sizeString!,
                      style: ChatDetailsFileRow.textInformationStyle(context),
                    ),
                    Text(
                      " - ",
                      style: ChatDetailsFileRow.textInformationStyle(context),
                    ),
                  ],
                  Flexible(
                    child: Text(
                      sentDate.localizedTime(context),
                      style: ChatDetailsFileRow.textInformationStyle(context),
                    ),
                  ),
                ],
              ),
              style.paddingBottomText,
            ],
          ),
        ),
      ],
    );
  }
}
