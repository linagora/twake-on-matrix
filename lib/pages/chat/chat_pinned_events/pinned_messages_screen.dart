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
        title: Text(
          L10n.of(context)!.pinnedMessages(controller.events.length),
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
              child: ListView.custom(
                controller: controller.scrollController,
                shrinkWrap: true,
                reverse: true,
                childrenDelegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // The message at this index:
                    final currentEventIndex =
                        controller.events.length - index - 1;
                    final event = controller.events[currentEventIndex];
                    final nextEvent = currentEventIndex > 0
                        ? controller.events[currentEventIndex - 1]
                        : null;
                    final previousEvent =
                        currentEventIndex < controller.events.length - 1
                            ? controller.events[currentEventIndex + 1]
                            : null;
                    return Builder(
                      builder: (context) {
                        return GestureDetector(
                          onSecondaryTapDown: (details) {
                            controller.handleContextMenuActionInEachMessage(
                              context,
                              event,
                            );
                          },
                          child: Message(
                            event!,
                            previousEvent: previousEvent,
                            nextEvent: nextEvent,
                            timeline: controller.widget.timeline!,
                            isHoverNotifier: controller.isHoverNotifier,
                            listHorizontalActionMenu: const [],
                            longPressSelect: true,
                            selectMode: false,
                          ),
                        );
                      },
                    );
                  },
                  childCount: controller.events.length,
                ),
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
