import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:twake_chat/presentation/decorators/chat_list/subtitle_image_preview_style.dart';

class ChatListFilePreview extends StatelessWidget {
  final String iconPath;
  final String text;
  final TextStyle? style;
  final int maxLines;

  const ChatListFilePreview({
    super.key,
    required this.iconPath,
    required this.text,
    required this.maxLines,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
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
