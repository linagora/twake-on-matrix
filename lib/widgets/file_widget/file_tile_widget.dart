import 'dart:typed_data';

import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/int_extension.dart';
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
    this.fileTileIcon,
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
  final String? fileTileIcon;
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
                const SizedBox(height: 4.0),
                FileNameText(
                  filename: filename,
                  highlightText: highlightText,
                  style: style,
                ),
                Row(
                  children: [
                    if (sizeString != null)
                      TextInformationOfFile(
                        value: sizeString!,
                        style: style,
                      ),
                    TextInformationOfFile(
                      value: " · ",
                      style: style,
                    ),
                    Flexible(
                      child: TextInformationOfFile(
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

class FileNameText extends StatelessWidget {
  const FileNameText({
    super.key,
    required this.filename,
    this.highlightText,
    this.style = const FileTileWidgetStyle(),
  });

  final String filename;
  final String? highlightText;
  final FileTileWidgetStyle style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: filename.buildHighlightTextSpans(
          highlightText ?? '',
          style: style.textStyle(context),
          highlightStyle: style.highlightTextStyle(context),
        ),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class TextInformationOfFile extends StatelessWidget {
  final String value;
  final FileTileWidgetStyle style;
  final ValueNotifier<DownloadPresentationState>? downloadFileStateNotifier;

  const TextInformationOfFile({
    super.key,
    required this.value,
    this.downloadFileStateNotifier,
    this.style = const FileTileWidgetStyle(),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (downloadFileStateNotifier != null)
          ValueListenableBuilder<DownloadPresentationState>(
            valueListenable: downloadFileStateNotifier!,
            builder: ((context, downloadFileState, child) {
              if (downloadFileState is DownloadingPresentationState &&
                  downloadFileState.total != null &&
                  downloadFileState.receive != null &&
                  downloadFileState.total! >= IntExtension.oneKB) {
                return Text(
                  '${downloadFileState.receive!.bytesToMB(placeDecimal: 1)} MB / ',
                  style: style.textInformationStyle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }
              return const SizedBox.shrink();
            }),
          ),
        Text(
          value,
          style: style.textInformationStyle(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
