import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/file_tile_widget_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FileTileWidget extends StatelessWidget {
  const FileTileWidget({
    super.key,
    required this.mimeType,
    required this.filename,
    this.fileType,
    this.highlightText,
    this.sizeString,
    this.backgroundColor,
  });

  final TwakeMimeType mimeType;
  final String filename;
  final String? highlightText;
  final String? sizeString;
  final Color? backgroundColor;
  final String? fileType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: FileTileWidgetStyle.paddingFileTileAll,
      decoration: ShapeDecoration(
        color: backgroundColor ?? FileTileWidgetStyle.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: FileTileWidgetStyle.borderRadius,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            mimeType.getIcon(fileType: fileType),
            width: FileTileWidgetStyle.iconSize,
            height: FileTileWidgetStyle.iconSize,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                _FileNameText(
                  filename: filename,
                  highlightText: highlightText,
                ),
                Row(
                  children: [
                    if (sizeString != null)
                      _TextInformationOfFile(value: sizeString!),
                    const _TextInformationOfFile(value: " · "),
                    Flexible(
                      child: _TextInformationOfFile(
                        value:
                            mimeType.getFileType(context, fileType: fileType),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FileNameText extends StatelessWidget {
  const _FileNameText({
    required this.filename,
    this.highlightText,
  });

  final String filename;
  final String? highlightText;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 2,
      text: TextSpan(
        children: filename.buildHighlightTextSpans(
          highlightText ?? '',
          style: FileTileWidgetStyle.textStyle(context),
          highlightStyle: FileTileWidgetStyle.highlightTextStyle(context),
        ),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _TextInformationOfFile extends StatelessWidget {
  final String value;
  const _TextInformationOfFile({required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: FileTileWidgetStyle.textInformationStyle(context),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
