import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_option_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatDetailsEditOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leading;
  final VoidCallback onTap;
  final double? leadingIconSize;
  final double? trailingIconSize;
  final Color? leadingIconColor;
  final Color? titleColor;
  final Color? subtitleColor;

  const ChatDetailsEditOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
    this.leadingIconSize,
    this.trailingIconSize,
    this.leadingIconColor,
    this.titleColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      clipBehavior: Clip.hardEdge,
      color: LinagoraSysColors.material().onPrimary,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: ChatDetailsEditOptionStyle.itemBuilderPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: ChatDetailsEditOptionStyle.leadingIconPadding,
                child: Icon(
                  leading,
                  size: leadingIconSize ??
                      ChatDetailsEditOptionStyle.defaultLeadingIconSize,
                  color: leadingIconColor ??
                      ChatDetailsEditOptionStyle.defaultLeadingIconColor(
                        context,
                      ),
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: subtitle.isEmpty
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: ChatDetailsEditOptionStyle.titleTextStyle(
                              context,
                              titleColor,
                            ),
                            maxLines: ChatDetailsEditOptionStyle.titleMaxLines,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(
                            padding: ChatDetailsEditOptionStyle
                                .subtitleItemBuilderPadding,
                            child: Text(
                              subtitle,
                              style:
                                  ChatDetailsEditOptionStyle.subtitleTextStyle(
                                context,
                                subtitleColor,
                              ),
                              maxLines:
                                  ChatDetailsEditOptionStyle.subtitleMaxLines,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_outlined,
                      size: trailingIconSize ??
                          ChatDetailsEditOptionStyle.defaultTrailingIconSize,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
