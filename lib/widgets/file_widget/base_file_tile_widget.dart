import 'dart:typed_data';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matrix/matrix.dart';

class BaseFileTileWidget extends StatelessWidget {
  const BaseFileTileWidget({
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
    this.ownMessage = false,
    required this.subTitle,
    this.event,
    this.onTap,
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
  final Widget Function(BuildContext) subTitle;
  final bool ownMessage;
  final Event? event;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: style.paddingFileTileAll,
            decoration: ShapeDecoration(
              color:
                  backgroundColor ??
                  style.backgroundColor(context, ownMessage: ownMessage),
              shape: RoundedRectangleBorder(borderRadius: style.borderRadius),
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
                      subTitle(context),
                      style.paddingBottomText,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ..._buildReplySpacing(),
        ..._buildLinkPreview(context),
      ],
    );
  }

  List<Widget> _buildReplySpacing() {
    if (event != null && event!.isReplyEvent() && event!.text.isEmpty) {
      return [const SizedBox(height: 16.0)];
    }
    return [];
  }

  List<Widget> _buildLinkPreview(BuildContext context) {
    if (event != null && event!.isCaptionModeOrReply()) {
      return [
        const SizedBox(height: 8.0),
        MouseRegion(
          cursor: SystemMouseCursors.copy,
          child: TwakeLinkPreview(
            key: ValueKey('TwakeLinkPreview%${event!.eventId}%'),
            event: event!,
            localizedBody: event!.body,
            ownMessage: ownMessage,
            fontSize: AppConfig.messageFontSize * AppConfig.fontSizeFactor,
            linkStyle: MessageContentStyle.linkStyleMessageContent(context),
            richTextStyle: event!.getMessageTextStyle(context),
            isCaption: event!.isCaptionModeOrReply(),
          ),
        ),
      ];
    }
    return [];
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
