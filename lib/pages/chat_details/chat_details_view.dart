import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/presentation/extensions/room_summary_extension.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/avatar/round_avatar_style.dart';
import 'package:linagora_design_flutter/extensions/string_extension.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/pages/chat_details/chat_details.dart';
import 'package:fluffychat/utils/string_extension.dart';

class ChatDetailsView extends StatelessWidget {
  final ChatDetailsController controller;

  const ChatDetailsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.room == null) {
      return Scaffold(
        backgroundColor: LinagoraSysColors.material().onPrimary,
        appBar: AppBar(
          backgroundColor: LinagoraSysColors.material().onPrimary,
          title: Text(L10n.of(context)!.oopsSomethingWentWrong),
        ),
        body: Center(
          child: Text(L10n.of(context)!.youAreNoLongerParticipatingInThisChat),
        ),
      );
    }
    return StreamBuilder(
      stream: controller.room?.onUpdate.stream,
      builder: (context, snapshot) {
        return Scaffold(
          floatingActionButton: _AddMembersButton(controller: controller),
          backgroundColor: LinagoraSysColors.material().onPrimary,
          appBar: TwakeAppBar(
            title: L10n.of(context)!.groupInformation,
            leading: TwakeIconButton(
              paddingAll: 8,
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: controller.widget.closeRightColumn,
              icon: controller.widget.isInStack
                  ? Icons.chevron_left_outlined
                  : Icons.close,
            ),
            centerTitle: true,
            withDivider: true,
            actions: [
              IconButton(
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: controller.onTapEditButton,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
            context: context,
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
                    backgroundColor: LinagoraSysColors.material().onPrimary,
                    toolbarHeight:
                        ChatDetailViewStyle.groupToolbarHeightSliverAppBar,
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GroupInformation(
                          avatarUri: controller.room?.avatar,
                          displayName:
                              controller.room?.getLocalizedDisplayname(),
                          membersCount:
                              controller.room?.summary.actualMembersCount,
                        ),
                        Padding(
                          padding: ChatDetailViewStyle
                              .groupDescriptionContainerPadding,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    LinagoraRefColors.material().neutral[90]!,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.info_outline),
                                  title: _TileTitleText(
                                    title: L10n.of(context)!.groupDescription,
                                  ),
                                  subtitle: _TileSubtitleText(
                                    subtitle: controller.room?.topic == null ||
                                            controller.room!.topic.isEmpty
                                        ? L10n.of(context)!.noDescription
                                        : controller.room!.topic,
                                  ),
                                ),
                                ValueListenableBuilder(
                                  valueListenable: controller.muteNotifier,
                                  builder: (context, pushRuleState, child) {
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.notifications_outlined,
                                      ),
                                      title: _TileTitleText(
                                        title: L10n.of(context)!.notifications,
                                      ),
                                      trailing: SizedBox(
                                        width: ChatDetailViewStyle
                                            .switchButtonWidth,
                                        height: ChatDetailViewStyle
                                            .switchButtonHeight,
                                        child: FittedBox(
                                          fit: BoxFit.fill,
                                          child: Switch(
                                            activeTrackColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            value: pushRuleState ==
                                                PushRuleState.notify,
                                            onChanged: (value) {
                                              controller.onToggleNotification();
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    automaticallyImplyLeading: false,
                    pinned: true,
                    floating: true,
                    forceElevated: innerBoxIsScrolled,
                    bottom: TabBar(
                      physics: const NeverScrollableScrollPhysics(),
                      overlayColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      indicatorPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                      ),
                      indicatorWeight: 3.0,
                      labelStyle:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      unselectedLabelStyle: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      tabs: controller.tabList.map((page) {
                        return Tab(
                          child: Text(
                            page.getTitle(context),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
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
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: controller.tabController,
                  children: controller.sharedPages().map((pages) {
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
}

class _AddMembersButton extends StatelessWidget {
  const _AddMembersButton({
    required this.controller,
  });

  final ChatDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => controller.onTapAddMembers(),
      borderRadius: ChatDetailViewStyle.borderRadiusButton,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ChatDetailViewStyle.addMemberMaxWidth,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: ChatDetailViewStyle.borderRadiusButton,
        ),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_outlined,
                  size: 18.0,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    L10n.of(context)!.addMember,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileSubtitleText extends StatelessWidget {
  const _TileSubtitleText({
    required this.subtitle,
  });

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle,
      maxLines: 1,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.tertiary,
          ),
    );
  }
}

class _TileTitleText extends StatelessWidget {
  const _TileTitleText({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}

class _GroupInformation extends StatelessWidget {
  const _GroupInformation({
    this.avatarUri,
    this.displayName,
    this.membersCount,
  });

  final Uri? avatarUri;
  final String? displayName;
  final int? membersCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: ChatDetailViewStyle.mainPadding,
          child: LayoutBuilder(
            builder: (context, constraints) => Builder(
              builder: (context) {
                final text = displayName?.getShortcutNameForAvatar() ?? '@';
                final placeholder = Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: text.avatarColors,
                      stops: RoundAvatarStyle.defaultGradientStops,
                    ),
                  ),
                  width: ChatDetailViewStyle.avatarSize,
                  height: ChatDetailViewStyle.avatarSize,
                  child: Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: ChatDetailViewStyle.avatarFontSize,
                        color: AvatarStyle.defaultTextColor(true),
                        fontFamily: AvatarStyle.fontFamily,
                        fontWeight: AvatarStyle.fontWeight,
                      ),
                    ),
                  ),
                );
                if (avatarUri == null) {
                  return placeholder;
                }
                return Avatar(
                  mxContent: avatarUri,
                  name: displayName,
                  size: ChatDetailViewStyle.avatarSize,
                  fontSize: ChatDetailViewStyle.avatarFontSize,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: ChatDetailViewStyle.chatInformationPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: LinagoraSysColors.material().onSurface,
                    ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              Text(
                membersCount != null
                    ? L10n.of(context)!.countMembers(membersCount!)
                    : '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LinagoraRefColors.material().tertiary[30],
                    ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
