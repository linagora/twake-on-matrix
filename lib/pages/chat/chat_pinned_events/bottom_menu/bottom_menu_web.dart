import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class BottomMenuWeb extends StatelessWidget {
  final ValueNotifier<List<Event>> selectedEvents;
  final void Function()? onCloseSelectionMode;
  final void Function()? onUnpinSelectedEvents;

  const BottomMenuWeb({
    super.key,
    required this.selectedEvents,
    this.onCloseSelectionMode,
    this.onUnpinSelectedEvents,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Event>>(
      valueListenable: selectedEvents,
      builder: (context, selectedEvents, child) {
        if (selectedEvents.isEmpty) return child!;

        return Padding(
          padding: PinnedMessagesStyle.actionBarParentPadding,
          child: Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(
              PinnedMessagesStyle.actionBarBorderRadius,
            ),
            child: Container(
              height: PinnedMessagesStyle.unpinButtonHeight,
              width: PinnedMessagesStyle.unpinButtonWidth,
              padding: PinnedMessagesStyle.actionBarPadding,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(
                  PinnedMessagesStyle.actionBarBorderRadius,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onCloseSelectionMode,
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: PinnedMessagesStyle.bottomMenuCloseButtonSize,
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
                    onPressed: onUnpinSelectedEvents,
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
