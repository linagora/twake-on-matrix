import 'package:animations/animations.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body_view_style.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view_builder.dart';
import 'package:fluffychat/pages/chat_list/space_view.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/stream_extension.dart';
import 'package:fluffychat/widgets/connection_status_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ChatListBodyView extends StatelessWidget {
  final ChatListController controller;

  const ChatListBodyView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusManager.instance.primaryFocus?.unfocus,
      excludeFromSemantics: true,
      behavior: HitTestBehavior.translucent,
      child: PageTransitionSwitcher(
        transitionBuilder: (
          Widget child,
          Animation<double> primaryAnimation,
          Animation<double> secondaryAnimation,
        ) {
          return SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.vertical,
            fillColor: LinagoraSysColors.material().onPrimary,
            child: child,
          );
        },
        child: SlidableAutoCloseBehavior(
          child: StreamBuilder(
            key: ValueKey(
              controller.activeClient.userID.toString() +
                  controller.activeFilter.toString() +
                  controller.activeSpaceId.toString(),
            ),
            stream: controller.activeClient.onSync.stream
                .where((s) => s.hasRoomUpdate)
                .rateLimit(const Duration(seconds: 1)),
            builder: (context, _) {
              if (controller.activeFilter == ActiveFilter.spaces) {
                return SpaceView(
                  controller,
                  scrollController: controller.scrollController,
                  key: Key(controller.activeSpaceId ?? 'Spaces'),
                );
              }
              if (controller.matrixState.waitForFirstSync &&
                  controller.activeClient.prevBatch != null) {
                if (controller.chatListBodyIsEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: ChatListBodyViewStyle.paddingIconSkeletons,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              ImagePaths.icSkeletons,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: ChatListBodyViewStyle.paddingOwnProfile,
                        child: FutureBuilder<Profile?>(
                          future: controller.activeClient
                              .fetchOwnProfile(getFromRooms: false),
                          builder: (context, snapshotProfile) {
                            if (snapshotProfile.connectionState !=
                                ConnectionState.done) {
                              return const SizedBox();
                            }
                            final name =
                                snapshotProfile.data?.displayName ?? '👋';
                            return Column(
                              children: [
                                Text(
                                  L10n.of(context)!.welcomeToTwake(name),
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                Padding(
                                  padding: ChatListBodyViewStyle
                                      .paddingTextStartNewChatMessage,
                                  child: Text(
                                    L10n.of(context)!.startNewChatMessage,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
                return SingleChildScrollView(
                  controller: controller.scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ConnectionStatusHeader(),
                      AnimatedContainer(
                        height: ChatListBodyViewStyle.heightIsTorBrowser(
                          controller.isTorBrowser,
                        ),
                        duration: TwakeThemes.animationDuration,
                        curve: TwakeThemes.animationCurve,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(),
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          child: ListTile(
                            leading: const Icon(Icons.vpn_key),
                            title: Text(L10n.of(context)!.dehydrateTor),
                            subtitle: Text(L10n.of(context)!.dehydrateTorLong),
                            trailing: const Icon(Icons.chevron_right_outlined),
                            onTap: controller.dehydrate,
                          ),
                        ),
                      ),
                      if (!controller.filteredRoomsForPinIsEmpty)
                        ValueListenableBuilder(
                          valueListenable: controller.expandRoomsForPinNotifier,
                          builder: (context, isExpanded, child) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ExpandableTitleBuilder(
                                  title: L10n.of(context)!.countPinChat(
                                    controller.filteredRoomsForPin.length,
                                  ),
                                  isExpanded: isExpanded,
                                  onTap: controller
                                      .expandRoomsForPinNotifier.toggle,
                                ),
                                if (isExpanded) child!,
                              ],
                            );
                          },
                          child: ChatListViewBuilder(
                            controller: controller,
                            rooms: controller.filteredRoomsForPin,
                          ),
                        ),
                      if (!controller.filteredRoomsForAllIsEmpty)
                        ValueListenableBuilder(
                          valueListenable: controller.expandRoomsForAllNotifier,
                          builder: (context, isExpanded, child) {
                            return Padding(
                              padding: ChatListBodyViewStyle
                                  .paddingTopExpandableTitleBuilder,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ExpandableTitleBuilder(
                                    title: L10n.of(context)!.countAllChat(
                                      controller.filteredRoomsForAll.length,
                                    ),
                                    isExpanded: isExpanded,
                                    onTap: controller
                                        .expandRoomsForAllNotifier.toggle,
                                  ),
                                  if (isExpanded) child!,
                                ],
                              ),
                            );
                          },
                          child: ChatListViewBuilder(
                            controller: controller,
                            rooms: controller.filteredRoomsForAll,
                          ),
                        ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class ExpandableTitleBuilder extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback? onTap;

  const ExpandableTitleBuilder({
    super.key,
    required this.title,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: ChatListBodyViewStyle.paddingHorizontalExpandableTitleBuilder,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: LinagoraRefColors.material().neutral[40],
                  ),
            ),
            Padding(
              padding: ChatListBodyViewStyle.paddingIconExpand,
              child: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: ChatListBodyViewStyle.sizeIconExpand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
