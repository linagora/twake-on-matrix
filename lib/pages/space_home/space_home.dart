import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/config/first_column_inner_routes.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/space_home/open_space_child.dart';
import 'package:twake_chat/pages/space_home/space_home_controller.dart';
import 'package:twake_chat/pages/space_home/space_home_style.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
import 'package:twake_chat/presentation/mixins/go_to_group_chat_mixin.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

/// What a space shows in place of a conversation: its name, who may come in,
/// what it is for, the things to do there and its channels, where the
/// conversations are.
class SpaceHome extends ConsumerStatefulWidget {
  const SpaceHome({super.key, required this.roomId, required this.onShowInfo});

  final String roomId;
  final VoidCallback onShowInfo;

  @override
  ConsumerState<SpaceHome> createState() => _SpaceHomeState();
}

class _SpaceHomeState extends ConsumerState<SpaceHome> {
  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(spaceHomeControllerProvider(widget.roomId).notifier).open(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final space = ref.watch(
      spaceHomeControllerProvider(widget.roomId).select((s) => s.space),
    );
    if (space == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: _SpaceHomeBar(space: space, onShowInfo: widget.onShowInfo),
      body: SingleChildScrollView(
        padding: SpaceHomeStyle.pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: SpaceHomeStyle.cardMaxWidth,
            ),
            child: Material(
              color: LinagoraSysColors.material().surface,
              borderRadius: BorderRadius.circular(SpaceHomeStyle.cardRadius),
              child: Padding(
                padding: SpaceHomeStyle.cardPadding,
                child: Column(
                  spacing: SpaceHomeStyle.gap,
                  children: [
                    _SpaceDescription(space: space),
                    _SpaceActions(space: space, onShowInfo: widget.onShowInfo),
                    _SpaceChannels(spaceId: space.id),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpaceHomeBar extends StatelessWidget implements PreferredSizeWidget {
  const _SpaceHomeBar({required this.space, required this.onShowInfo});

  final SpaceSummary space;
  final VoidCallback onShowInfo;

  @override
  Size get preferredSize => const Size.fromHeight(SpaceHomeStyle.barHeight);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LinagoraSysColors.material().onPrimary,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: onShowInfo,
          child: Padding(
            padding: SpaceHomeStyle.barPadding,
            // The bar has a fixed height: the text must not outgrow it.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: SpaceHomeStyle.barMaxTextScale,
              child: Row(
                spacing: SpaceHomeStyle.gap,
                children: [
                  if (ResponsiveUtils().isSingleColumnLayout(context))
                    TwakeIconButton(
                      paddingAll: SpaceHomeStyle.backPadding,
                      icon: Icons.arrow_back_ios,
                      tooltip: L10n.of(context)!.back,
                      onTap: () => const RoomsRoute().go(context),
                    ),
                  Avatar(
                    mxContent: space.avatar,
                    name: space.name,
                    size: SpaceHomeStyle.headerAvatarSize,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          space.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          L10n.of(context)!.spaceMemberCount(space.memberCount),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpaceDescription extends StatelessWidget {
  const _SpaceDescription({required this.space});

  final SpaceSummary space;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      spacing: SpaceHomeStyle.gap,
      children: [
        Avatar(
          mxContent: space.avatar,
          name: space.name,
          size: SpaceHomeStyle.cardAvatarSize,
        ),
        Text(
          space.name,
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: SpaceHomeStyle.smallGap,
          runSpacing: SpaceHomeStyle.smallGap,
          children: [
            Icon(
              space.isPublic ? Icons.public : Icons.lock_outline,
              size: SpaceHomeStyle.kindIconSize,
            ),
            Text(
              space.isPublic ? l10n.spacePublic : l10n.spacePrivate,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l10n.spaceMemberCount(space.memberCount),
              style: textTheme.bodyMedium,
            ),
          ],
        ),
        if (space.topic.isNotEmpty)
          Text(
            space.topic,
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _SpaceActions extends StatelessWidget with GoToGroupChatMixin {
  const _SpaceActions({required this.space, required this.onShowInfo});

  final SpaceSummary space;
  final VoidCallback onShowInfo;

  /// The same flow as from the list, already in this space. On the web it
  /// opens in the list's navigator: a narrow window must then show the list.
  void _newGroup(BuildContext context) {
    final routes = FirstColumnInnerRoutes.instance;
    goToNewGroupChat(routes.innerContextFrom(context), parentSpaceId: space.id);
    if (!routes.goRouteAvailableInFirstColumn() &&
        ResponsiveUtils().isSingleColumnLayout(context)) {
      const RoomsRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: SpaceHomeStyle.smallGap,
      runSpacing: SpaceHomeStyle.smallGap,
      children: [
        if (space.canInvite)
          LinagoraButton(
            key: const ValueKey('space_invite'),
            icon: Icons.person_add_alt_outlined,
            label: l10n.spaceInvitePeople,
            onPressed: () => InviteRoute(roomid: space.id).go(context),
          ),
        if (space.canAddChildren)
          LinagoraButton(
            key: const ValueKey('space_new_group'),
            icon: Icons.supervisor_account_outlined,
            label: l10n.spaceNewGroup,
            onPressed: () => _newGroup(context),
          ),
        LinagoraIconButton(
          key: const ValueKey('space_open_info'),
          icon: Icons.settings_outlined,
          tooltip: l10n.spaceShowInfo,
          onPressed: onShowInfo,
        ),
      ],
    );
  }
}

class _SpaceChannels extends ConsumerWidget {
  const _SpaceChannels({required this.spaceId});

  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    final children = ref.watch(spaceChildrenProvider(spaceId));
    final value = children.value;
    if (value != null && value.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinagoraSectionHeader(label: l10n.spaceChannels),
          for (final child in value)
            LinagoraSettingItem(
              key: ValueKey('space_channel_${child.roomId}'),
              title: child.name,
              leading: Avatar(
                mxContent: child.avatar,
                name: child.name,
                size: SpaceHomeStyle.channelAvatarSize,
              ),
              onTap: () => openSpaceChild(
                context,
                ref,
                parentSpaceId: spaceId,
                child: child,
              ),
            ),
        ],
      );
    }
    if (children.hasError) {
      return Column(
        spacing: SpaceHomeStyle.smallGap,
        children: [
          Text(l10n.spaceChannelsFailed),
          LinagoraButton(
            key: const ValueKey('space_channels_retry'),
            variant: LinagoraButtonVariant.text,
            label: l10n.spaceChannelsRetry,
            onPressed: () => ref.invalidate(spaceChildrenProvider(spaceId)),
          ),
        ],
      );
    }
    return value == null
        ? const CircularProgressIndicator()
        : const SizedBox.shrink();
  }
}
