import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/presentation/extensions/room_summary_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
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

  const ChatDetailsView(this.controller, {Key? key}) : super(key: key);

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

    controller.members!.removeWhere((u) => u.membership == Membership.leave);
    return StreamBuilder(
      stream: controller.room?.onUpdate.stream,
      builder: (context, snapshot) {
        return Scaffold(
          floatingActionButton: _AddMembersButton(controller: controller),
          backgroundColor: LinagoraSysColors.material().onPrimary,
          appBar: AppBar(
            backgroundColor: LinagoraSysColors.material().onPrimary,
            automaticallyImplyLeading: false,
            bottom: PreferredSize(
              preferredSize: const Size(double.infinity, 1),
              child: Container(
                color: LinagoraStateLayer(
                  LinagoraSysColors.material().surfaceTint,
                ).opacityLayer1,
                height: 1,
              ),
            ),
            title: Padding(
              padding: ChatDetailViewStyle.navigationAppBarPadding,
              child: Row(
                children: [
                  Padding(
                    padding: ChatDetailViewStyle.backIconPadding,
                    child: IconButton(
                      splashColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onPressed: controller.widget.onBack,
                      icon: controller.widget.isInStack
                          ? const Icon(Icons.arrow_back)
                          : const Icon(Icons.close),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      L10n.of(context)!.groupInformation,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: controller.onTapEditButton,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
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
                        ChatDetailViewStyle.toolbarHeightSliverAppBar,
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
                      overlayColor: MaterialStateProperty.all(
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
                      tabs: controller.chatDetailsPages().map((pages) {
                        return Tab(
                          child: Text(
                            pages.page.getTitle(context),
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
}

class _AddMembersButton extends StatelessWidget {
  const _AddMembersButton({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final ChatDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => controller.onTapAddMembers(),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 156,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(28),
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
    Key? key,
    required this.subtitle,
  }) : super(key: key);

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
    Key? key,
    required this.title,
  }) : super(key: key);

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
    Key? key,
    this.avatarUri,
    this.displayName,
    this.membersCount,
  }) : super(key: key);

  final Uri? avatarUri;
  final String? displayName;
  final int? membersCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Builder(
            builder: (context) {
              final text = displayName?.getShortcutNameForAvatar() ?? '@';
              final placeholder = Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: text.avatarColors,
                    stops: RoundAvatarStyle.defaultGradientStops,
                  ),
                ),
                width: constraints.maxWidth,
                height: ChatDetailViewStyle.avatarHeight,
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
              return MxcImage(
                uri: avatarUri,
                width: constraints.maxWidth,
                height: ChatDetailViewStyle.avatarHeight,
                fit: BoxFit.cover,
                placeholder: (_) => placeholder,
                cacheKey: avatarUri.toString(),
                noResize: true,
              );
            },
          ),
        ),
        Padding(
          padding: ChatDetailViewStyle.mainPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                displayName ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: LinagoraSysColors.material().onSurface,
                    ),
                maxLines: 2,
              ),
              Text(
                membersCount != null
                    ? L10n.of(context)!.countMembers(membersCount!)
                    : '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LinagoraRefColors.material().tertiary[30],
                    ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
