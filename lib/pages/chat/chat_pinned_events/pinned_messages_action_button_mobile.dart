import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class PinnedMessagesActionButton extends StatelessWidget {
  const PinnedMessagesActionButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: PinnedMessagesStyle.unpinButtonSizeMobile,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onTap,
          icon: PinnedMessagesStyle.unpinIcon(
            size: PinnedMessagesStyle.unpinButtonSizeMobile,
          ),
        ),
        const SizedBox(height: PinnedMessagesStyle.menuActionBtnGapMobile),
        Text(
          L10n.of(context)!.unpin,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
