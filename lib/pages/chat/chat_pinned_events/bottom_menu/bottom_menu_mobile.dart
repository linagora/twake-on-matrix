import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class BottomMenuMobile extends StatelessWidget {
  final ValueNotifier<List<Event>> selectedEvents;
  final void Function()? onUnpinAll;
  final void Function()? onUnpinSelectedEvents;

  const BottomMenuMobile({
    super.key,
    required this.selectedEvents,
    required this.onUnpinAll,
    this.onUnpinSelectedEvents,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PinnedMessagesStyle.bottomMenuHeightMobile,
      child: ValueListenableBuilder<List<Event>>(
        valueListenable: selectedEvents,
        builder: (context, selectedEvents, child) {
          if (selectedEvents.isEmpty) return child!;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
          );
        },
        child: Center(
          child: TextButton.icon(
            onPressed: onUnpinAll,
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
