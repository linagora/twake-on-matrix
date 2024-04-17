import 'dart:async';

import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item_web/chat_details_files_item_view_web.dart';
import 'package:fluffychat/widgets/mixins/download_file_on_web_mixin.dart';
import 'package:fluffychat/widgets/mixins/handle_download_and_preview_file_mixin.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatDetailsFileItemWeb extends StatefulWidget {
  const ChatDetailsFileItemWeb({super.key, required this.event});

  final Event event;

  @override
  State<ChatDetailsFileItemWeb> createState() => ChatDetailsFileItemWebState();
}

class ChatDetailsFileItemWebState extends State<ChatDetailsFileItemWeb>
    with
        HandleDownloadAndPreviewFileMixin,
        DownloadFileOnWebMixin<ChatDetailsFileItemWeb> {
  @override
  Event get event => widget.event;

  @override
  Future<void> get handlePreview => handlePreviewWeb(
        event: widget.event,
        context: TwakeApp.routerKey.currentContext!,
      );

  @override
  Widget build(BuildContext context) {
    return ChatDetailsFilesViewWeb(controller: this);
  }
}
