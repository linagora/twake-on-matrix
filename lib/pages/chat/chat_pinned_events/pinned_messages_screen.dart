import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_style.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PinnedMessagesScreen extends StatelessWidget {
  final PinnedMessagesController controller;

  const PinnedMessagesScreen(this.controller, {super.key});

  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                        return Message(
                          event!,
                          previousEvent: previousEvent,
                          nextEvent: nextEvent,
                          timeline: controller.widget.timeline!,
                          isHoverNotifier: controller.isHoverNotifier,
                          listHorizontalActionMenu: const [],
                          longPressSelect: true,
                          selectMode: false,
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
                                              ?.copyWith(color: action.color),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                      childCount: controller.eventsNotifier.value.length,
                    ),
                  );
                },
              ),
            ),
          ),
          if (responsiveUtils.isMobile(context)) ...[
            Divider(
              height: 0.5,
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            SizedBox(
              height: PinnedMessagesStyle.unpinButtonHeight,
              width: MediaQuery.of(context).size.width,
              child: TextButton(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      ImagePaths.icUnpin,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    PinnedMessagesStyle.paddingIconAndUnpin,
                    Text(
                      L10n.of(context)!.unpinAllMessages,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                onPressed: () {
                  controller.unpinAll();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
