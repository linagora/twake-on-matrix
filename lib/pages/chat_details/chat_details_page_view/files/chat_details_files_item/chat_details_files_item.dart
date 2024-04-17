import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item_view.dart';
import 'package:fluffychat/widgets/mixins/download_file_on_mobile_mixin.dart';
import 'package:fluffychat/widgets/mixins/handle_download_and_preview_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatDetailsFileItem extends StatefulWidget {
  const ChatDetailsFileItem({super.key, required this.event});

  final Event event;

  @override
  State<ChatDetailsFileItem> createState() => ChatDetailsFileItemController();
}

class ChatDetailsFileItemController extends State<ChatDetailsFileItem>
    with
        HandleDownloadAndPreviewFileMixin,
        DownloadFileOnMobileMixin<ChatDetailsFileItem> {
  @override
  Event get event => widget.event;

  @override
  Widget build(BuildContext context) {
    return ChatDetailsFilesView(controller: this);
  }
}
