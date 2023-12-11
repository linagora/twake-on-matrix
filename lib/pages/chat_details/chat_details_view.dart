import 'package:fluffychat/pages/chat_details/chat_details_header_view.dart';
import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/presentation/extensions/room_summary_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/pages/chat_details/chat_details.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';

class ChatDetailsView extends StatelessWidget {
  final ChatDetailsController controller;

  const ChatDetailsView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller.room == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(L10n.of(context)!.oopsSomethingWentWrong),
        ),
        body: Center(
          child: Text(L10n.of(context)!.youAreNoLongerParticipatingInThisChat),
        ),
      );
    }

    controller.members!.removeWhere((u) => u.membership == Membership.leave);
    return StreamBuilder(
      stream: controller.room?.onUpdate.stream,
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: controller.isMobileAndTablet
              ? Theme.of(context).colorScheme.background
              : Theme.of(context).colorScheme.surfaceVariant,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black.withOpacity(0.15)),
                  ),
                ),
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.background,
            title: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TwakeIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => context.pop(),
                    tooltip: L10n.of(context)!.back,
                    paddingAll: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  Expanded(
                    child: Text(
                      L10n.of(context)!.chatInfo,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                    ),
                  ),
                  const SizedBox(width: 56),
                ],
              ),
            ),
          ),
          body: NestedScrollView(
            physics: const ClampingScrollPhysics(),
            key: controller.nestedScrollViewState,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar(
                    toolbarHeight:
                        ChatDetailViewStyle.toolbarHeightSliverAppBar,
                    title: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _groupAvatarBuilder(
                            context: context,
                            room: controller.room!,
                          ),
                          _groupNameAndInfoBuilder(
                            context: context,
                            room: controller.room!,
                          ),
                          ValueListenableBuilder(
                            valueListenable: controller.muteNotifier,
                            builder: (context, pushRuleState, child) {
                              final buttons =
                                  controller.chatDetailsActionsButton();
                              return ActionsHeaderBuilder(
                                actions: buttons,
                                width: ChatDetailViewStyle.actionsHeaderWidth(
                                  context,
                                ),
                                buttonColor: !controller.isMobileAndTablet
                                    ? LinagoraRefColors.material().primary[100]
                                    : null,
                                borderSide: BorderSide(
                                  width: 1,
                                  color: controller.isMobileAndTablet
                                      ? LinagoraRefColors.material()
                                          .neutral[90]!
                                      : Colors.transparent,
                                ),
                                onTap: (actions) =>
                                    controller.onTapActionsButton(
                                  actions,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    automaticallyImplyLeading: false,
                    pinned: true,
                    floating: true,
                    forceElevated: innerBoxIsScrolled,
                    bottom: TabBar(
                      physics: const NeverScrollableScrollPhysics(),
                      overlayColor: MaterialStateProperty.all(
                        Colors.transparent,
                      ),
                      tabs: controller.chatDetailsPages().map((pages) {
                        return Tab(
                          child: Text(
                            pages.page.getTitle(context),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        );
                      }).toList(),
                      controller: controller.tabController,
                    ),
                  ),
                ),
              ];
            },
            body: ClipRRect(
              borderRadius: BorderRadius.all(
                Radius.circular(
                  ChatDetailViewStyle.chatDetailsPageViewWebBorderRadius,
                ),
              ),
              child: Container(
                width: ChatDetailViewStyle.chatDetailsPageViewWebWidth,
                padding: ChatDetailViewStyle.paddingTabBarView,
                decoration: BoxDecoration(
                  color: LinagoraRefColors.material().primary[100],
                ),
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: controller.tabController,
                  children: controller.chatDetailsPages().map((pages) {
                    return pages.child;
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Padding _groupAvatarBuilder({
    required BuildContext context,
    required Room room,
  }) {
    return Padding(
      padding: ChatDetailViewStyle.groupAvatarPadding,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          ChatDetailViewStyle.groupAvatarBorderRadius,
        ),
        onTap: room.canSendEvent('m.room.avatar')
            ? controller.setAvatarAction
            : null,
        child: Hero(
          tag: 'content_banner',
          child: Avatar(
            mxContent: room.avatar,
            name: room.getLocalizedDisplayname(
              MatrixLocals(L10n.of(context)!),
            ),
            size: ChatDetailViewStyle.groupAvatarSize,
          ),
        ),
      ),
    );
  }

  Padding _groupNameAndInfoBuilder({
    required BuildContext context,
    required Room room,
  }) {
    final actualMembersCount = room.summary.actualMembersCount;
    return Padding(
      padding: ChatDetailViewStyle.groupNameAndInfoPadding,
      child: Column(
        children: [
          Text(
            room.getLocalizedDisplayname(
              MatrixLocals(L10n.of(context)!),
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            actualMembersCount > 1
                ? L10n.of(context)!.countMembers(
                    actualMembersCount,
                  )
                : L10n.of(context)!.emptyChat,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LinagoraRefColors.material().tertiary[20],
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
