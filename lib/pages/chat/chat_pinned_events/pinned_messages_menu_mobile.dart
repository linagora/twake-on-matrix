import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_action_button_mobile.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class PinnedMessagesMenuMobile extends StatelessWidget {
  const PinnedMessagesMenuMobile({
    super.key,
    required this.controller,
  });

  final PinnedMessagesController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PinnedMessagesStyle.menuHeightMobile,
      child: ValueListenableBuilder<List<Event>>(
        valueListenable: controller.selectedEvents,
        builder: (context, selectedEvents, child) {
          if (selectedEvents.isEmpty) return child!;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PinnedMessagesActionButton(
                onTap: controller.unpinSelectedEvents,
              ),
            ],
          );
        },
        child: Center(
          child: TextButton.icon(
            onPressed: () => controller.unpinAll(),
            icon: PinnedMessagesStyle.unpinIcon(),
            label: Text(
              L10n.of(context)!.unpinAllMessages,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
