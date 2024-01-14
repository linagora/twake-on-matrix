import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_style.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class PinnedMessagesScreen extends StatelessWidget {
  final PinnedMessagesController controller;

  const PinnedMessagesScreen(this.controller, {super.key});

  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: AppBar(
        backgroundColor: LinagoraSysColors.material().onPrimary,
        title: ValueListenableBuilder(
          valueListenable: controller.eventsNotifier,
          builder: (context, events, child) {
            return Text(
              L10n.of(context)!.pinnedMessages(events.length),
            );
          },
        ),
        leading: TwakeIconButton(
          tooltip: L10n.of(context)!.back,
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!responsiveUtils.isMobile(context))
            Builder(
              builder: (context) {
                return TwakeIconButton(
                  icon: Icons.more_vert,
                  tooltip: L10n.of(context)!.more,
                  onTap: () =>
                      controller.handleContextMenuActionInMore(context),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: PinnedMessagesStyle.paddingListMessages(context),
              child: ValueListenableBuilder(
                valueListenable: controller.eventsNotifier,
                builder: (context, events, child) {
                  return ListView.custom(
                    controller: controller.scrollController,
                    shrinkWrap: true,
                    reverse: true,
                    childrenDelegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // The message at this index:
                        final currentEventIndex = events.length - index - 1;
                        final event = events[currentEventIndex];
                        final nextEvent = currentEventIndex > 0
                            ? events[currentEventIndex - 1]
                            : null;
                        final previousEvent =
                            currentEventIndex < events.length - 1
                                ? events[currentEventIndex + 1]
                                : null;
                        return ValueListenableBuilder<List<Event>>(
                          valueListenable: controller.selectedEvents,
                          builder: (context, selectedEvents, child) {
                            return Message(
                              event!,
                              previousEvent: previousEvent,
                              nextEvent: nextEvent,
                              timeline: controller.widget.timeline!,
                              isHoverNotifier: controller.isHoverNotifier,
                              listHorizontalActionMenu: const [],
                              longPressSelect: true,
                              selectMode: selectedEvents.isNotEmpty,
                              onSelect: controller.onSelectMessage,
                              selected: controller.isSelected(event),
                              menuChildren: (context) => controller
                                  .pinnedMessagesActionsList
                                  .map(
                                    (action) => InkWell(
                                      onTap: () {
                                        action.onTap?.call(extra: event);
                                        Navigator.of(context).pop();
                                      },
                                      child: Container(
                                        height: PinnedMessagesStyle
                                            .heightContextMenuItem,
                                        padding: const EdgeInsets.all(
                                          PinnedMessagesStyle
                                              .paddingAllContextMenuItem,
                                        ),
                                        child: Row(
                                          children: [
                                            if (action.imagePath != null)
                                              SvgPicture.asset(
                                                action.imagePath!,
                                                colorFilter: ColorFilter.mode(
                                                  action.color ??
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                            if (action.iconData != null)
                                              Icon(
                                                action.iconData,
                                                color: action.color,
                                              ),
                                            if (action.imagePath != null ||
                                                action.iconData != null)
                                              PinnedMessagesStyle
                                                  .paddingIconAndUnpin,
                                            Text(
                                              action.text,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    color: action.color,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        );
                      },
                      childCount: events.length,
                    ),
                  );
                },
              ),
            ),
          ),
          ValueListenableBuilder<List<Event>>(
            valueListenable: controller.selectedEvents,
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
                          onPressed: controller.closeSelectionMode,
                          icon: Icon(
                            Icons.close,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        Text(
                          L10n.of(context)!
                              .messageSelected(selectedEvents.length),
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => controller.unpinSelectedEvents(),
                          icon: PinnedMessagesStyle.unpinIcon(),
                          label: Text(
                            L10n.of(context)!.unpin,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
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
          ),
        ],
      ),
    );
  }
}
