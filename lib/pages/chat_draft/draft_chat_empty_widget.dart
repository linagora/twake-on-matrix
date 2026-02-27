import 'package:fluffychat/pages/chat_draft/draft_chat_empty_widget_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

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
        constraints: const BoxConstraints(maxWidth: 286),
        decoration: BoxDecoration(
          color: DraftChatEmptyWidgetStyle.greetingButtonBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(ImagePaths.mascotDraftChat),
            const SizedBox(height: 8),
            Text(
              L10n.of(context)!.sendMessageGuide,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: LinagoraRefColors.material().tertiary[20],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L10n.of(context)!.noMessageHereYet,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: LinagoraSysColors.material().onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
