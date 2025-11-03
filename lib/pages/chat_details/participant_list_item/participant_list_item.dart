import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/enums/selection_mode_enum.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/participant_list_item/participant_list_item_style.dart';
import 'package:fluffychat/pages/chat_list/chat_custom_slidable_action.dart';
import 'package:fluffychat/pages/profile_info/profile_info_page.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/manager/twake_user_info_manager/twake_user_info_manager.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/utils/user_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ParticipantListItem extends StatefulWidget {
  final User member;

  final VoidCallback? onUpdatedMembers;
  final SelectionModeEnum selectionMode;
  final void Function(User member)? onSelectMember;
  final bool isMembersSelecting;
  final void Function(User member)? onRemoveMember;

  const ParticipantListItem(
    this.member, {
    super.key,
    this.onUpdatedMembers,
    this.selectionMode = SelectionModeEnum.unavailable,
    this.onSelectMember,
    this.isMembersSelecting = false,
    this.onRemoveMember,
  });

  @override
  State<ParticipantListItem> createState() => _ParticipantListItemState();
}

class _ParticipantListItemState extends State<ParticipantListItem> {
  final ValueNotifier<bool> isHoverParticipantItemNotifier =
      ValueNotifier(false);

  @override
  void dispose() {
    isHoverParticipantItemNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = TwakeInkWell(
      onTap: () async => await _onItemTap(context),
      onLongPress: () => widget.onSelectMember?.call(widget.member),
      onHover: (hover) {
        if (widget.member.room.canBanMemberInRoom(widget.member) &&
            !ParticipantListItemStyle.responsiveUtils.isMobile(context)) {
          isHoverParticipantItemNotifier.value = hover;
        }
      },
      child: TwakeListItem(
        key: ValueKey<String>(widget.member.id),
        height: 72,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            _ParticipantSelectionToggleButton(
              selectionMode: widget.selectionMode,
              onTap: () => widget.onSelectMember?.call(widget.member),
            ),
            Opacity(
              opacity: widget.member.membership == Membership.join ? 1 : 0.5,
              child: Avatar(
                mxContent: widget.member.avatarUrl,
                name: widget.member.calcDisplayname(),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Opacity(
                opacity: widget.member.membership == Membership.join ? 1 : 0.5,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Flexible(
                                child: FutureBuilder(
                                  future: getIt
                                      .get<TwakeUserInfoManager>()
                                      .getTwakeProfileFromUserId(
                                        client: Matrix.of(context).client,
                                        userId: widget.member.id,
                                      ),
                                  builder: (context, asyncSnapshot) {
                                    return Text(
                                      asyncSnapshot.data?.displayName ??
                                          widget.member.calcDisplayname(),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: LinagoraTextStyle.material()
                                          .bodyMedium2
                                          .copyWith(
                                            color: LinagoraSysColors.material()
                                                .onSurface,
                                          ),
                                    );
                                  },
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable: isHoverParticipantItemNotifier,
                                builder: (context, isHover, _) {
                                  if (!isHover) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: Text(
                                        widget.member.getDefaultPowerLevelMember
                                            .displayName(context),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color:
                                                  LinagoraRefColors.material()
                                                      .tertiary[30],
                                            ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            widget.member.id,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      LinagoraRefColors.material().tertiary[30],
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: isHoverParticipantItemNotifier,
                      builder: (context, isHover, _) {
                        if (!isHover) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: InkWell(
                            splashColor:
                                LinagoraHoverStyle.material().hoverColor,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(32),
                            ),
                            onTap: () {
                              widget.onRemoveMember?.call(widget.member);
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(32),
                                ),
                              ),
                              width: 32,
                              height: 32,
                              child: Icon(
                                Icons.delete_outlined,
                                size: 18,
                                color:
                                    LinagoraRefColors.material().tertiary[30],
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
      ),
    );

    if (widget.isMembersSelecting) return child;

    return _ParticipantSlidable(
      slideActions: [
        _ParticipantBanAction(widget.member, onDone: widget.onUpdatedMembers),
      ],
      child: child,
    );
  }

  Future _onItemTap(BuildContext context) async {
    if (PlatformInfos.isMobile &&
        widget.selectionMode != SelectionModeEnum.unavailable) {
      widget.onSelectMember?.call(widget.member);
      return;
    }

    final responsive = getIt.get<ResponsiveUtils>();

    if (responsive.isMobile(context)) {
      await _openDialogInvite(context);
    } else {
      await widget.member.openProfileView(
        context: context,
        onUpdatedMembers: widget.onUpdatedMembers,
        onTransferOwnershipSuccess: () {
          Navigator.of(context).pop();
        },
      );
    }
  }

  Future _openDialogInvite(BuildContext context) async {
    if (PlatformInfos.isMobile) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (ctx) => ProfileInfoPage(
            roomId: widget.member.room.id,
            userId: widget.member.id,
            onUpdatedMembers: widget.onUpdatedMembers,
            onTransferOwnershipSuccess: () {
              Navigator.of(ctx).pop();
            },
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
          roomId: widget.member.room.id,
          userId: widget.member.id,
          onUpdatedMembers: widget.onUpdatedMembers,
          onNewChatOpen: () {
            Navigator.of(dialogContext).pop();
          },
          onTransferOwnershipSuccess: () {
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
