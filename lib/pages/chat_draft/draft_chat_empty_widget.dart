import 'package:fluffychat/pages/chat_draft/draft_chat_empty_widget_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class DraftChatEmpty extends StatelessWidget {
  final void Function()? onTap;

  const DraftChatEmpty({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(
          maxWidth: 236,
        ),
        decoration: BoxDecoration(
          color: DraftChatEmptyWidgetStyle.greetingButtonBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              L10n.of(context)!.noMessageHereYet,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L10n.of(context)!.sendMessageGuide,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 15,
                color: Color(0xFF818C99),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '🤗',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.merge(const TextStyle(fontSize: 88)),
            ),
          ],
        ),
      ),
    );
  }
}
