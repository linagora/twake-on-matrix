import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/bottom_menu/bottom_menu_mobile.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/bottom_menu/bottom_menu_web.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_style.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

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
        centerTitle: true,
        title: ValueListenableBuilder(
          valueListenable: controller.eventsNotifier,
          builder: (context, events, child) {
            return Text(
              L10n.of(context)!.pinnedMessages(events.length),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            );
          },
        ),
        leading: TwakeIconButton(
          tooltip: L10n.of(context)!.back,
          icon: Icons.chevron_left_outlined,
          onTap: controller.onClickBackButton,
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
                              listHorizontalActionMenu:
                                  controller.listHorizontalActionMenuBuilder(),
                              onMenuAction:
                                  controller.handleHorizontalActionMenu,
                              onHover: (isHover, event) =>
                                  controller.onHover(isHover, index, event),
                              selectMode: selectedEvents.isNotEmpty,
                              onSelect: controller.onSelectMessage,
                              selected: controller.isSelected(event),
                              menuChildren: (context) =>
                                  controller.pinnedMessagesActionsList(
                                context,
                                controller.getPinnedMessagesActionsList(event),
                                event,
                              ),
                              onLongPress: (event) =>
                                  controller.onLongPressMessage(
                                context,
                                event,
                              ),
                              listAction: controller
                                  .pinnedMessagesContextMenuActionsList(
                                context,
                                event,
                              ),
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
          responsiveUtils.isMobile(context)
              ? BottomMenuMobile(
                  selectedEvents: controller.selectedEvents,
                  onUnpinAll: controller.unpinAll,
                  onUnpinSelectedEvents: controller.unpinSelectedEvents,
                )
              : BottomMenuWeb(
                  selectedEvents: controller.selectedEvents,
                  onCloseSelectionMode: controller.closeSelectionMode,
                  onUnpinSelectedEvents: controller.unpinSelectedEvents,
                ),
        ],
      ),
    );
  }
}
