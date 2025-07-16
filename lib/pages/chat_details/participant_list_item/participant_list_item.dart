import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/enums/selection_mode_enum.dart';
import 'package:fluffychat/pages/chat_list/chat_custom_slidable_action.dart';
import 'package:fluffychat/pages/profile_info/profile_info_page.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/utils/user_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ParticipantListItem extends StatelessWidget {
  final User member;

  final VoidCallback? onUpdatedMembers;
  final SelectionModeEnum selectionMode;
  final void Function(User member)? onSelectMember;
  final bool isMembersSelecting;

  const ParticipantListItem(
    this.member, {
    super.key,
    this.onUpdatedMembers,
    this.selectionMode = SelectionModeEnum.unavailable,
    this.onSelectMember,
    this.isMembersSelecting = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = TwakeInkWell(
      onTap: () async => await _onItemTap(context),
      onLongPress: () => onSelectMember?.call(member),
      child: TwakeListItem(
        height: 72,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            _ParticipantSelectionToggleButton(
              selectionMode: selectionMode,
              onTap: () => onSelectMember?.call(member),
            ),
            Opacity(
              opacity: member.membership == Membership.join ? 1 : 0.5,
              child: Avatar(
                mxContent: member.avatarUrl,
                name: member.calcDisplayname(),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Opacity(
                opacity: member.membership == Membership.join ? 1 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            member.calcDisplayname(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: LinagoraTextStyle.material()
                                .bodyMedium2
                                .copyWith(
                                  color: LinagoraSysColors.material().onSurface,
                                ),
                          ),
                        ),
                        if (member.getDefaultPowerLevelMember.powerLevel >=
                            DefaultPowerLevelMember.owner.powerLevel) ...[
                          Text(
                            member.getDefaultPowerLevelMember
                                .displayName(context),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color:
                                      LinagoraRefColors.material().tertiary[30],
                                ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      member.id,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LinagoraRefColors.material().tertiary[30],
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isMembersSelecting) return child;

    return _ParticipantSlidable(
      slideActions: [
        _ParticipantBanAction(member, onDone: onUpdatedMembers),
      ],
      child: child,
    );
  }

  Future _onItemTap(BuildContext context) async {
    if (PlatformInfos.isMobile &&
        selectionMode != SelectionModeEnum.unavailable) {
      onSelectMember?.call(member);
      return;
    }

    final responsive = getIt.get<ResponsiveUtils>();

    if (responsive.isMobile(context)) {
      await _openDialogInvite(context);
    } else {
      await member.openProfileDialog(
        context: context,
        onUpdatedMembers: onUpdatedMembers,
      );
    }
  }

  Future _openDialogInvite(BuildContext context) async {
    if (PlatformInfos.isMobile) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (ctx) => ProfileInfoPage(
            roomId: member.room.id,
            userId: member.id,
            onUpdatedMembers: onUpdatedMembers,
          ),
        ),
      );
      return;
    }
    await showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      useRootNavigator: !PlatformInfos.isMobile,
      builder: (dialogContext) {
        return ProfileInfoPage(
          roomId: member.room.id,
          userId: member.id,
          onUpdatedMembers: onUpdatedMembers,
          onNewChatOpen: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }
}

class _ParticipantSelectionToggleButton extends StatelessWidget {
  const _ParticipantSelectionToggleButton({
    required this.selectionMode,
    required this.onTap,
  });

  final SelectionModeEnum selectionMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (selectionMode == SelectionModeEnum.unavailable) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8.0),
      child: Checkbox(
        value: selectionMode == SelectionModeEnum.selected,
        side: BorderSide(
          color: selectionMode == SelectionModeEnum.selected
              ? Theme.of(context).colorScheme.primary
              : LinagoraRefColors.material().tertiary[30]!,
          width: 2,
        ),
        onChanged: (_) => onTap(),
      ),
    );
  }
}

class _ParticipantSlidable extends StatelessWidget {
  const _ParticipantSlidable({required this.child, required this.slideActions});

  final Widget child;
  final List<Widget> slideActions;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      useTextDirection: true,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: slideActions.length * 0.23,
        children: slideActions,
      ),
      child: child,
    );
  }
}

class _ParticipantBanAction extends StatelessWidget {
  const _ParticipantBanAction(this.member, {required this.onDone});

  final User member;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return ChatCustomSlidableAction(
      label: L10n.of(context)!.remove,
      icon: Icon(
        Icons.person_remove_outlined,
        color: LinagoraSysColors.material().onPrimary,
      ),
      onPressed: (context) async {
        if (!member.canBan) {
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.removeMemberSelectionError,
          );
          return;
        }

        final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () => member.ban(),
        );
        if (result.error != null) {
          TwakeSnackBar.show(context, result.error!.message);
          return;
        }

        onDone?.call();
      },
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      backgroundColor: LinagoraSysColors.material().error,
    );
  }
}
