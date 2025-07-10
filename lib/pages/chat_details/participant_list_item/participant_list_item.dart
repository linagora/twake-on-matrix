import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/enums/selection_mode_enum.dart';
import 'package:fluffychat/pages/chat_details/participant_list_item/participant_list_item_style.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
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
    final child = Opacity(
      opacity: member.membership == Membership.join ? 1 : 0.5,
      child: TwakeInkWell(
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
              Avatar(
                mxContent: member.avatarUrl,
                name: member.calcDisplayname(),
              ),
              const SizedBox(width: 8.0),
              Expanded(
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
            ],
          ),
        ),
      ),
    );

    if (isMembersSelecting) return child;

    return _ParticipantDismissible(
      member: member,
      onDismissed: () => onUpdatedMembers?.call(),
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
      await _openProfileDialog(context);
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

  Future _openProfileDialog(BuildContext context) => showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          contentPadding: const EdgeInsets.all(0),
          backgroundColor: LinagoraRefColors.material().primary[100],
          surfaceTintColor: Colors.transparent,
          content: SizedBox(
            width: ParticipantListItemStyle.fixedDialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: ParticipantListItemStyle.closeButtonPadding,
                        child: IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ),
                    ProfileInfoBody(
                      user: member,
                      onNewChatOpen: () {
                        Navigator.of(dialogContext).pop();
                      },
                      onUpdatedMembers: onUpdatedMembers,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
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

class _ParticipantDismissible extends StatelessWidget {
  const _ParticipantDismissible({
    required this.member,
    required this.onDismissed,
    required this.child,
  });

  final User member;
  final VoidCallback onDismissed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(member.id),
      direction: DismissDirection.endToStart,
      background: Container(
        constraints: const BoxConstraints(maxWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: LinagoraRefColors.material().error[40],
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_remove_outlined,
              size: 24,
              color: LinagoraRefColors.material().primary[100],
            ),
            const SizedBox(height: 4),
            Text(
              L10n.of(context)!.remove,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: LinagoraRefColors.material().primary[100],
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        if (!member.canKick) {
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.removeMemberSelectionError,
          );
          return false;
        }

        final confirmResult = await showConfirmAlertDialog(
          context: context,
          title: L10n.of(context)!.removeUserConfirmationTitle,
          message: L10n.of(context)!.removeUserConfirmationMessage,
          okLabel: L10n.of(context)!.removeUser,
          cancelLabel: L10n.of(context)!.cancel,
          okLabelButtonColor: LinagoraSysColors.material().error,
          showCloseButton: true,
        );
        if (confirmResult == ConfirmResult.cancel) return false;

        final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () => member.kick(),
        );
        if (result.error != null) {
          TwakeSnackBar.show(context, result.error!.message);
          return false;
        }

        return true;
      },
      onDismissed: (_) => onDismissed(),
      child: child,
    );
  }
}
