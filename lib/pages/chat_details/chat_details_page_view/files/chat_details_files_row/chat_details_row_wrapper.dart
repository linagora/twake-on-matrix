import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item_style.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatDetailsFileRowWrapper extends StatelessWidget {
  final Widget child;
  final String? mimeType;
  final String? fileType;

  const ChatDetailsFileRowWrapper({
    super.key,
    required this.child,
    required this.mimeType,
    required this.fileType,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: ChatDetailsFileTileStyle.wrapperLeftPadding,
        ),
        SvgPicture.asset(
          mimeType.getIcon(fileType: fileType),
          width: ChatDetailsFileTileStyle().iconSize,
          height: ChatDetailsFileTileStyle().iconSize,
        ),
        ChatDetailsFileTileStyle().paddingRightIcon,
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
