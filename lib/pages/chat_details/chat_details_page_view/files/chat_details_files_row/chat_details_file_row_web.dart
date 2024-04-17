import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/widgets/file_widget/base_file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatDetailsFileTileRowWeb extends StatelessWidget {
  const ChatDetailsFileTileRowWeb({
    super.key,
    required this.mimeType,
    required this.filename,
    required this.sentDate,
    required this.style,
    required this.fileType,
    required this.sizeString,
  });

  final TwakeMimeType mimeType;
  final String filename;
  final String? sizeString;
  final String? fileType;
  final FileTileWidgetStyle style;
  final DateTime sentDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: style.paddingFileTileAll,
      decoration: ShapeDecoration(
        color: style.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: style.borderRadius,
        ),
      ),
      child: Row(
        crossAxisAlignment: style.crossAxisAlignment,
        children: [
          SvgPicture.asset(
            mimeType.getIcon(fileType: fileType),
            width: style.iconSize,
            height: style.iconSize,
          ),
          style.paddingRightIcon,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  FileNameText(
                    filename: filename,
                    style: style,
                  ),
                  Row(
                    children: [
                      if (sizeString != null) ...[
                        Text(
                          sizeString!,
                          style: style.textInformationStyle(
                            context,
                          ),
                        ),
                      ],
                    ],
                  ),
                  style.paddingBottomText,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              sentDate.localizedTimeShort(context),
              style: style.textInformationStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}
