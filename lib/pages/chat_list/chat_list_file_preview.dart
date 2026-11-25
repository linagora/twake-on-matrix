import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/presentation/decorators/chat_list/subtitle_image_preview_style.dart';
import 'package:twake_chat/utils/extension/mime_type_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

class ChatListFilePreview extends StatelessWidget {
  final Event event;
  final String text;
  final TextStyle? style;
  final int maxLines;

  const ChatListFilePreview({
    super.key,
    required this.event,
    required this.text,
    required this.maxLines,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          event.mimeType.getIcon(fileType: event.fileType),
          width: SubtitleImagePreviewStyle.width,
          height: SubtitleImagePreviewStyle.height,
        ),
        Flexible(
          child: Padding(
            padding: SubtitleImagePreviewStyle.labelPadding,
            child: Text(
              text,
              softWrap: false,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      ],
    );
  }
}
