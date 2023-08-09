import 'package:fluffychat/domain/model/extensions/mime_type_extension.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';

class MessageDownloadContent extends StatelessWidget {
  final Event event;
  final Color textColor;
  final ChatController controller;
  
  const MessageDownloadContent(
    this.event,
    this.textColor,
    {Key? key, required this.controller,})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filename = event.filename;
    final filetype = event.fileType;
    final sizeString = event.sizeString;

    Logs().i('filename: $filename, filetype: $filetype, sizeString: $sizeString, content: ${event.content}');
    return InkWell(
      onTap: () async {
        controller.onFileTapped(event: event);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: ShapeDecoration(
          color: LinagoraSysColors.material().surfaceTint.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SvgPicture.asset(
                event.getIcon(),
                width: 36,
                height: 36,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    filename,
                    maxLines: 1,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (sizeString != null)
                        _TextInformationOfFile(value: sizeString),
                      const _TextInformationOfFile(value: " · "),
                      Flexible(
                        child: _TextInformationOfFile(
                         value: event.getFileType(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _TextInformationOfFile extends StatelessWidget {
  final String value;
  const _TextInformationOfFile({required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.bodySmall!.copyWith(
        color: LinagoraRefColors.material().neutral,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

