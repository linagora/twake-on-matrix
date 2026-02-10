import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/enums/selection_mode_enum.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/participant_list_item/chat_participant_context_menu_item.dart';
import 'package:fluffychat/pages/chat_details/participant_list_item/mobile_context_menu_overlay.dart';
import 'package:fluffychat/pages/chat_details/participant_list_item/participant_list_item_style.dart';
import 'package:fluffychat/pages/chat_list/chat_custom_slidable_action.dart';
import 'package:fluffychat/pages/profile_info/profile_info_page.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/utils/user_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_mixin.dart';
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
  final void Function(User member, {DefaultPowerLevelMember? role})?
  onChangeRole;

  const ParticipantListItem(
    this.member, {
    super.key,
    this.onUpdatedMembers,
    this.selectionMode = SelectionModeEnum.unavailable,
    this.onSelectMember,
    this.isMembersSelecting = false,
    this.onRemoveMember,
    this.onChangeRole,
  });

  @override
  State<ParticipantListItem> createState() => _ParticipantListItemState();
}

class _ParticipantListItemState extends State<ParticipantListItem>
    with TwakeContextMenuMixin {
  final ValueNotifier<bool> isHoverParticipantItemNotifier = ValueNotifier(
    false,
  );
  final GlobalKey _participantItemKey = GlobalKey();

  bool get canChangePermissions =>
      widget.member.room.canUpdateRoleInRoom(widget.member);

  @override
  void dispose() {
    isHoverParticipantItemNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleName = ValueListenableBuilder(
      valueListenable: isHoverParticipantItemNotifier,
      builder: (context, isHover, child) {
        if (!isHover) {
          return child ?? const SizedBox.shrink();
        }
        return const SizedBox.shrink();
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Text(
          widget.member.getDefaultPowerLevelMember.displayName(
            context,
            hidden: [DefaultPowerLevelMember.member],
          ),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: LinagoraRefColors.material().tertiary[30],
          ),
        ),
      ),
    );

    Widget child = TwakeInkWell(
      onTap: () async => await _onItemTap(context),
      onLongPress: () => _handleLongPress(context),
      onHover: (hover) {
        if (widget.member.room.canBanMemberInRoom(widget.member) &&
            !ParticipantListItemStyle.responsiveUtils.isMobile(context)) {
          isHoverParticipantItemNotifier.value = hover;
        }
      },
      child: TwakeListItem(
        key: _participantItemKey,
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
                                child: Text(
                                  widget.member.calcDisplayname(),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: LinagoraTextStyle.material()
                                      .bodyMedium2
                                      .copyWith(
                                        color: LinagoraSysColors.material()
                                            .onSurface,
                                      ),
                                ),
                              ),
                              roleName,
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            widget.member.id,
                            style: Theme.of(context).textTheme.bodyMedium
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

    child = _ParticipantSlidable(
      slideActions: [
        _ParticipantBanAction(widget.member, onDone: widget.onUpdatedMembers),
      ],
      child: child,
    );

    if (PlatformInfos.isWeb) {
      child = GestureDetector(
        onSecondaryTapDown: (_) async => await _handleRightClick(context),
        child: child,
      );
    } else {
      child = Hero(
        tag: 'participant_context_menu_${widget.member.id}',
        child: ColoredBox(
          color: LinagoraSysColors.material().onPrimary,
          child: child,
        ),
      );
    }

    return child;
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

  ChatParticipantContextMenuItem _buildMenuItem({
    required BuildContext context,
    required String name,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final refColor = LinagoraRefColors.material();
    final sysColor = LinagoraSysColors.material();

    return ChatParticipantContextMenuItem(
      name: name,
      icon: icon,
      styleName: textTheme.bodyLarge?.copyWith(
        fontSize: 17,
        height: 24 / 17,
        color: isDestructive ? sysColor.error : refColor.neutral[30],
      ),
      colorIcon: isDestructive ? sysColor.error : refColor.neutral[30],
      onTap: onTap,
    );
  }

  List<ChatParticipantContextMenuItem> _buildContextMenuActions(
    BuildContext context,
  ) {
    final l10n = L10n.of(context)!;

    return [
      if (PlatformInfos.isMobile)
        _buildMenuItem(
          context: context,
          name: l10n.select,
          icon: Icons.check_box_outlined,
          onTap: () => widget.onSelectMember?.call(widget.member),
        ),
      if (canChangePermissions) ...[
        _buildMenuItem(
          context: context,
          name: l10n.promoteToAdmin,
          icon: Icons.star_border,
          onTap: () => widget.onChangeRole?.call(
            widget.member,
            role: DefaultPowerLevelMember.admin,
          ),
        ),
        _buildMenuItem(
          context: context,
          name: l10n.changePermissions,
          icon: Icons.admin_panel_settings_outlined,
          onTap: () => widget.onChangeRole?.call(widget.member),
        ),
      ],
      if (widget.onRemoveMember != null)
        _buildMenuItem(
          context: context,
          name: l10n.removeFromGroup,
          icon: Icons.block,
          onTap: () => widget.onRemoveMember!(widget.member),
          isDestructive: true,
        ),
    ];
  }

  /// Handles long press gesture on mobile devices.
  /// Shows floating context menu if user has permissions, otherwise triggers member selection.
  void _handleLongPress(BuildContext context) {
    if (PlatformInfos.isMobile &&
        canChangePermissions &&
        widget.onRemoveMember != null) {
      _showMobileContextMenu(context);
    } else {
      widget.onSelectMember?.call(widget.member);
    }
  }

  /// Shows mobile context menu with floating effect using Hero animation.
  /// Displays the participant item centered with dark background and context menu below.
  Future<void> _showMobileContextMenu(BuildContext context) async {
    try {
      final RenderBox? renderBox =
          _participantItemKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final size = renderBox.size;
      final screenSize = MediaQuery.sizeOf(context);

      final menuActions = _buildContextMenuActions(context);
      const menuSpacing = 8.0;

      // Center the item horizontally and vertically
      final centeredItemPosition = Offset(
        (screenSize.width - size.width) / 2,
        (screenSize.height - size.height) / 2,
      );

      // Position context menu centered horizontally, 8px below the centered item
      // Subtract half menu width to center it (TwakeContextMenu positions from left edge)
      final menuPosition = Offset(
        (screenSize.width - ParticipantListItemStyle.contextMenuWidth) /
            2, // Center the menu
        centeredItemPosition.dy + size.height + menuSpacing,
      );

      final selectedIndex = await Navigator.of(context).push<int>(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, animation, __) {
            return MobileContextMenuOverlay(
              itemPosition: centeredItemPosition,
              itemSize: size,
              menuPosition: menuPosition,
              menuActions: menuActions,
              member: widget.member,
              animation: animation,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );

      if (selectedIndex != null &&
          selectedIndex >= 0 &&
          selectedIndex < menuActions.length) {
        menuActions[selectedIndex].onTap.call();
      }
    } catch (e, s) {
      Logs().e('ParticipantListItem::_showMobileContextMenu()', e, s);
      if (mounted) {
        TwakeSnackBar.show(context, L10n.of(context)!.oopsSomethingWentWrong);
      }
    }
  }

  Future<void> _handleRightClick(BuildContext context) async {
    if (!canChangePermissions) return;
    try {
      disableRightClick();

      final RenderBox? renderBox =
          _participantItemKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        enableRightClick();
        return;
      }

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      final menuActions = _buildContextMenuActions(context);
      const itemHeight = 48.0;
      final menuHeight = menuActions.length * itemHeight;

      final menuPosition = Offset(
        position.dx + size.width - 8,
        position.dy + size.height - 16 - menuHeight,
      );

      final selectedIndex = await showTwakeContextMenu(
        offset: menuPosition,
        context: context,
        listActions: menuActions,
        onClose: enableRightClick,
        leadingIcon: true,
      );
      if (selectedIndex is int &&
          selectedIndex >= 0 &&
          selectedIndex < menuActions.length) {
        menuActions[selectedIndex].onTap.call();
      }
    } catch (e) {
      Logs().e('ParticipantListItem::_handleRightClick()', e);
      enableRightClick();
      if (mounted) {
        TwakeSnackBar.show(context, L10n.of(context)!.oopsSomethingWentWrong);
      }
    }
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
