import 'package:fluffychat/pages/chat_details/chat_details_edit_option_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatDetailsEditOption extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? counterText;
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
    this.subtitle,
    required this.leading,
    required this.onTap,
    this.counterText,
    this.leadingIconSize,
    this.trailingIconSize,
    this.leadingIconColor,
    this.titleColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ChatDetailsEditOptionStyle.itemOptionPadding,
      child: TwakeInkWell(
        onTap: onTap,
        child: Padding(
          padding: ChatDetailsEditOptionStyle.itemBuilderPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: ChatDetailsEditOptionStyle.leadingIconPadding,
                child: Icon(
                  leading,
                  size:
                      leadingIconSize ??
                      ChatDetailsEditOptionStyle.defaultLeadingIconSize,
                  color:
                      leadingIconColor ??
                      ChatDetailsEditOptionStyle.defaultLeadingIconColor(
                        context,
                      ),
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style:
                                    ChatDetailsEditOptionStyle.titleTextStyle(
                                      context,
                                      titleColor,
                                    ),
                                maxLines:
                                    ChatDetailsEditOptionStyle.titleMaxLines,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (counterText != null &&
                                  counterText!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Text(
                                    counterText!,
                                    style:
                                        ChatDetailsEditOptionStyle.subtitleTextStyle(
                                          context,
                                          subtitleColor,
                                        ),
                                    maxLines: ChatDetailsEditOptionStyle
                                        .subtitleMaxLines,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty)
                            Padding(
                              padding: ChatDetailsEditOptionStyle
                                  .subtitleItemBuilderPadding,
                              child: Text(
                                subtitle!,
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
                      size:
                          trailingIconSize ??
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
