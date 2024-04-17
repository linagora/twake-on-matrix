import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item_style.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ChatDetailsDownloadFileTileWidget extends StatelessWidget {
  const ChatDetailsDownloadFileTileWidget({
    super.key,
    required this.onTap,
    required this.trailingIcon,
    required this.iconColor,
    required this.filename,
    required this.mimeType,
    required this.fileType,
    required this.sizeString,
    required this.sentDate,
  });

  final GestureTapCallback onTap;
  final IconData trailingIcon;
  final Color iconColor;
  final String filename;
  final String? mimeType;
  final String? fileType;
  final String? sizeString;
  final DateTime sentDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 8,
        ),
        SvgPicture.asset(
          mimeType.getIcon(fileType: fileType),
          width: ChatDetailsFileTileStyle().iconSize,
          height: ChatDetailsFileTileStyle().iconSize,
        ),
        ChatDetailsFileTileStyle().paddingRightIcon,
        Expanded(
          child: Column(
            children: [
              ChatDetailsFileTileRow(
                onTap: onTap,
                trailingIcon: trailingIcon,
                iconColor: iconColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (sizeString != null) ...[
                          Text(
                            sizeString!,
                            style: ChatDetailsFileTileStyle()
                                .textInformationStyle(context),
                          ),
                          Text(
                            " - ",
                            style: ChatDetailsFileTileStyle()
                                .textInformationStyle(context),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            sentDate.localizedTime(context),
                            style: ChatDetailsFileTileStyle()
                                .textInformationStyle(context),
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
      ],
    );
  }
}

class ChatDetailsDownloadedFileTileWidget extends StatelessWidget {
  const ChatDetailsDownloadedFileTileWidget({
    super.key,
    required this.onTap,
    required this.trailingIcon,
    required this.iconColor,
    required this.filename,
    required this.mimeType,
    required this.fileType,
  });

  final GestureTapCallback onTap;
  final IconData trailingIcon;
  final Color iconColor;
  final String filename;
  final String? mimeType;
  final String? fileType;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 8,
        ),
        SvgPicture.asset(
          mimeType.getIcon(fileType: fileType),
          width: ChatDetailsFileTileStyle().iconSize,
          height: ChatDetailsFileTileStyle().iconSize,
        ),
        ChatDetailsFileTileStyle().paddingRightIcon,
        Expanded(
          child: ChatDetailsFileTileRow(
            onTap: onTap,
            trailingIcon: trailingIcon,
            iconColor: iconColor,
            child: RichText(
              maxLines: 3,
              text: TextSpan(
                text: filename,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: LinagoraSysColors.material().primary),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class ChatDetailsFileTileRow extends StatelessWidget {
  const ChatDetailsFileTileRow({
    super.key,
    required this.child,
    required this.onTap,
    required this.trailingIcon,
    required this.iconColor,
  });

  final GestureTapCallback onTap;
  final IconData trailingIcon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: LinagoraSysColors.material().surfaceVariant,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: ChatDetailsFileTileStyle.dividerHeight,
              color: ChatDetailsFileTileStyle.dividerColor(context),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                trailingIcon,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
