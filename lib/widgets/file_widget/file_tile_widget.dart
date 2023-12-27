import 'dart:typed_data';

import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget_style.dart';
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
    this.imageBytes,
    this.style = const FileTileWidgetStyle(),
  });

  final TwakeMimeType mimeType;
  final String filename;
  final String? highlightText;
  final String? sizeString;
  final Color? backgroundColor;
  final String? fileType;
  final Uint8List? imageBytes;
  final FileTileWidgetStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: style.paddingFileTileAll,
      decoration: ShapeDecoration(
        color: backgroundColor ?? style.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: style.borderRadius,
        ),
      ),
      child: Row(
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
            ),
          if (imageBytes == null)
            SvgPicture.asset(
              mimeType.getIcon(fileType: fileType),
              width: style.iconSize,
              height: style.iconSize,
            ),
          style.paddingRightIcon,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 4.0),
                _FileNameText(
                  filename: filename,
                  highlightText: highlightText,
                  style: style,
                ),
                Row(
                  children: [
                    if (sizeString != null)
                      _TextInformationOfFile(
                        value: sizeString!,
                        style: style,
                      ),
                    _TextInformationOfFile(
                      value: " · ",
                      style: style,
                    ),
                    Flexible(
                      child: _TextInformationOfFile(
                        value: mimeType.getFileType(
                          context,
                          fileType: fileType,
                        ),
                        style: style,
                      ),
                    ),
                  ],
                ),
                style.paddingBottomText,
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
    this.style = const FileTileWidgetStyle(),
  });

  final String filename;
  final String? highlightText;
  final FileTileWidgetStyle style;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 2,
      text: TextSpan(
        children: filename.buildHighlightTextSpans(
          highlightText ?? '',
          style: style.textStyle(context),
          highlightStyle: style.highlightTextStyle(context),
        ),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _TextInformationOfFile extends StatelessWidget {
  final String value;
  final FileTileWidgetStyle style;
  const _TextInformationOfFile({
    required this.value,
    this.style = const FileTileWidgetStyle(),
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: style.textInformationStyle(context),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
