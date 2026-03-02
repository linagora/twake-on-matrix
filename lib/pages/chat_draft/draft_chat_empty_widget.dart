import 'package:fluffychat/pages/chat_draft/draft_chat_empty_widget_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DraftChatEmpty extends StatelessWidget {
  final void Function()? onTap;

  const DraftChatEmpty({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: BoxConstraints(
          maxWidth: DraftChatEmptyWidgetStyle.maxWidth(context),
        ),
        decoration: BoxDecoration(
          color: DraftChatEmptyWidgetStyle.greetingButtonBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              ImagePaths.mascotNewChat,
              width: DraftChatEmptyWidgetStyle.iconSize(context),
              height: DraftChatEmptyWidgetStyle.iconSize(context),
            ),
            const SizedBox(height: 8),
            Text(
              L10n.of(context)!.sendMessageGuide,
              textAlign: TextAlign.center,
              style: DraftChatEmptyWidgetStyle.subTitleStyle(context),
            ),
            const SizedBox(height: 8),
            Text(
              L10n.of(context)!.noMessageHereYet,
              style: DraftChatEmptyWidgetStyle.titleStyle(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
