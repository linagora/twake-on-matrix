import 'package:fluffychat/pages/chat/chat.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';

class MessageDownloadContent extends StatelessWidget {
  final Event event;
  final Color textColor;
  final ChatController controller;

  static const defaultUnknownMimeType = 'application/octet-stream';

  const MessageDownloadContent(
    this.event,
    this.textColor,
    {Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filename = event.filename;
    final filetype = event.fileType;
    final sizeString = event.sizeString;
    return InkWell(
      onTap: () async {
        controller.onFileTapped(event: event);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.file_download_outlined,
                  color: textColor,
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    filename,
                    maxLines: 2,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Text(
                  filetype ?? defaultUnknownMimeType,
                  style: TextStyle(
                    color: textColor.withAlpha(150),
                  ),
                ),
                const Spacer(),
                if (sizeString != null)
                  Text(
                    sizeString,
                    style: TextStyle(
                      color: textColor.withAlpha(150),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
