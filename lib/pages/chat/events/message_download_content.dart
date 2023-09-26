import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/chat_room_search_state.dart';
import 'package:fluffychat/domain/model/extensions/mime_type_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/color_extension.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';

class MessageDownloadContent extends StatelessWidget {
  final Event event;
  final void Function(Event event) onFileTapped;

  final ValueNotifier<Either<Failure, Success>>? searchStatus;

  const MessageDownloadContent(
    this.event, {
    Key? key,
    required this.onFileTapped,
    this.searchStatus,
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
      onTap: () async {
        onFileTapped(event);
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
                  if (searchStatus != null) ...[
                    ValueListenableBuilder(
                      valueListenable: searchStatus!,
                      builder: (context, searchStatusValue, child) {
                        final success = searchStatusValue
                            .getSuccessOrNull<ChatRoomSearchSuccess>();
                        final searchKeyword = success?.keyword ?? '';
                        return _FileNameWithSearchText(
                          filename: filename,
                          searchKeyword: searchKeyword,
                        );
                      },
                    ),
                  ] else ...[
                    _FileNameText(filename: filename),
                  ],
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

class _FileNameWithSearchText extends StatelessWidget {
  const _FileNameWithSearchText({
    required this.filename,
    required this.searchKeyword,
  });

  final String filename;
  final String searchKeyword;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      text: TextSpan(
        children: filename.buildHighlightTextSpans(
          searchKeyword,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
          highlightStyle: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontWeight: FontWeight.bold,
            backgroundColor: CssColor.fromCss('gold'),
          ),
        ),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _FileNameText extends StatelessWidget {
  const _FileNameText({
    required this.filename,
  });

  final String filename;

  @override
  Widget build(BuildContext context) {
    return Text(
      filename,
      maxLines: 1,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onBackground,
        fontWeight: FontWeight.bold,
      ),
      overflow: TextOverflow.ellipsis,
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
