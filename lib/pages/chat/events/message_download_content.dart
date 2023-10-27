import 'package:fluffychat/domain/model/extensions/mime_type_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/color_extension.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class MessageDownloadContent extends StatelessWidget {
  final Event event;
  final void Function(Event event)? onFileTapped;

  final ValueNotifier<String>? highlightNotifier;
  final String? highlightText;

  const MessageDownloadContent(
    this.event, {
    Key? key,
    this.onFileTapped,
    this.highlightNotifier,
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
                  if (highlightNotifier != null) ...[
                    ValueListenableBuilder(
                      valueListenable: highlightNotifier!,
                      builder: (context, highlightText, child) {
                        return _FileNameText(
                          filename: filename,
                          highlightText: highlightText,
                        );
                      },
                    ),
                  ] else ...[
                    _FileNameText(
                      filename: filename,
                      highlightText: highlightText,
                    ),
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

class _FileNameText extends StatelessWidget {
  const _FileNameText({
    required this.filename,
    this.highlightText,
  });

  final String filename;
  final String? highlightText;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      text: TextSpan(
        children: filename.buildHighlightTextSpans(
          highlightText ?? '',
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
