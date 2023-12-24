import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/file_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class MessageDownloadContent extends StatelessWidget {
  final Event event;
  final void Function(Event event)? onFileTapped;

  final String? highlightText;

  const MessageDownloadContent(
    this.event, {
    Key? key,
    this.onFileTapped,
    this.highlightText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filename = event.filename;
    final filetype = event.fileType;
    final sizeString = event.sizeString;

    Logs().i(
      'filename: $filename, filetype: $filetype, sizeString: $sizeString, content: ${event.content}',
    );
    return InkWell(
      onTap: onFileTapped != null
          ? () {
              onFileTapped?.call(event);
            }
          : null,
      child: FileTileWidget(
        mimeType: event.mimeType,
        fileType: filetype,
        filename: filename,
        highlightText: highlightText,
        sizeString: sizeString,
      ),
    );
  }
}
