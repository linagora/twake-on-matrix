import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class PinnedMessagesMenuWeb extends StatelessWidget {
  const PinnedMessagesMenuWeb({
    super.key,
    required this.controller,
  });

  final PinnedMessagesController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Event>>(
      valueListenable: controller.selectedEvents,
      builder: (context, selectedEvents, child) {
        if (selectedEvents.isEmpty) return child!;

        return Padding(
          padding: PinnedMessagesStyle.actionBarParentPaddingWeb,
          child: Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(
              PinnedMessagesStyle.actionBarBorderRadiusWeb,
            ),
            child: Container(
              height: PinnedMessagesStyle.unpinButtonHeightWeb,
              width: PinnedMessagesStyle.unpinButtonWidthWeb,
              padding: PinnedMessagesStyle.actionBarPaddingWeb,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(
                  PinnedMessagesStyle.actionBarBorderRadiusWeb,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: controller.closeSelectionMode,
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: PinnedMessagesStyle.closeSelectionIconSizeWeb,
                    ),
                  ),
                  Text(
                    L10n.of(context)!.messageSelected(selectedEvents.length),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => controller.unpinSelectedEvents(),
                    icon: PinnedMessagesStyle.unpinIcon(),
                    label: Text(
                      L10n.of(context)!.unpin,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
