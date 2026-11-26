import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/domain/model/room/room_preview_result.dart';
import 'package:twake_chat/presentation/mixins/chat_list_item_mixin.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list_row_divider.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_title.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/space_row_body.dart';
import 'package:twake_chat/presentation/model/chat_list/space_row_data.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/avatar/avatar_with_kind_badge.dart';
import 'package:twake_chat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

enum ArchivedRoomAction { delete, rejoin }

class ChatListItem extends StatelessWidget with ChatListItemMixin {
  final Room room;
  final bool activeChat;
  final bool isSelectedItem;
  final bool isEnableSelectMode;
  final Widget? checkBoxWidget;
  final void Function()? onTap;
  final void Function()? onTapAvatar;
  final void Function(TapDownDetails)? onSecondaryTapDown;
  final void Function()? onLongPress;
  final RoomPreviewResult? previewResult;

  /// How deep the row is in its space.
  final int depth;

  /// What the row of a space shows and does beyond a room's.
  final SpaceRowData? space;

  const ChatListItem(
    this.room, {
    this.checkBoxWidget,
    this.activeChat = false,
    this.isSelectedItem = false,
    this.isEnableSelectMode = false,
    this.onTap,
    this.onTapAvatar,
    this.onSecondaryTapDown,
    this.onLongPress,
    this.previewResult,
    this.depth = 0,
    this.space,
    super.key,
  });

  void clickAction(BuildContext context) async {
    if (onTap != null) return onTap!();
    switch (room.membership) {
      case Membership.ban:
        TwakeSnackBar.show(
          context,
          L10n.of(context)!.youHaveBeenBannedFromThisChat,
        );
        return;
      case Membership.leave:
        ArchiveRoomRoute(roomid: room.id).go(context);
        return;
      case Membership.invite:
      case Membership.join:
        RoomRoute(roomid: room.id).go(context);
      default:
        return;
    }
  }

  Future<void> archiveAction(BuildContext context) async {
    {
      if ([Membership.leave, Membership.ban].contains(room.membership)) {
        await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () => room.forget(),
        );
        return;
      }
      final confirmed = await showOkCancelAlertDialog(
        useRootNavigator: false,
        context: context,
        title: L10n.of(context)!.areYouSure,
        okLabel: L10n.of(context)!.yes,
        cancelLabel: L10n.of(context)!.no,
      );
      if (confirmed == OkCancelResult.cancel) return;
      await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () => room.leave(),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChild = depth > 0;
    final isTopSpace = space != null && !isChild;
    return Padding(
      padding: ChatListItemStyle.padding,
      child: TwakeInkWell(
        isSelected: activeChat,
        onTap: () => clickAction(context),
        onSecondaryTapDown: onSecondaryTapDown,
        onLongPress: onLongPress,
        child: _HeroUsersLoader(
          room: room,
          builder: (context) {
            final displayName = room.getLocalizedDisplayname(
              MatrixLocals(L10n.of(context)!),
            );
            return Container(
              height: space != null
                  ? ChatListItemStyle.spaceItemHeight
                  : ChatListItemStyle.chatItemHeight,
              padding: ChatListItemStyle.paddingBody.add(
                EdgeInsetsDirectional.only(
                  start: depth * ChatListItemStyle.depthIndent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isEnableSelectMode) checkBoxWidget ?? const SizedBox(),
                  Padding(
                    padding: isTopSpace
                        ? ChatListItemStyle.paddingSpaceAvatar
                        : ChatListItemStyle.paddingAvatar,
                    child: _ChatListAvatar(
                      room: room,
                      name: displayName,
                      size: isChild
                          ? ChatListItemStyle.childAvatarSize
                          : isTopSpace
                          ? ChatListItemStyle.spaceAvatarSize
                          : AvatarStyle.defaultSize,
                      onTap: onTapAvatar,
                    ),
                  ),
                  Expanded(
                    child: ChatListRowDivider(
                      child: Row(
                        children: [
                          Expanded(
                            child: switch (space) {
                              final SpaceRowData space => SpaceRowBody(
                                name: displayName,
                                space: space,
                                isPinned: room.isFavourite,
                                isInvitation: room.isInvitation,
                              ),
                              null => Column(
                                children: [
                                  ChatListItemTitle(
                                    room: room,
                                    originServerTs: switch (previewResult) {
                                      RoomPreviewFound(:final event) =>
                                        event.originServerTs,
                                      _ => null,
                                    },
                                  ),
                                  ChatListItemSubtitle(
                                    room: room,
                                    previewResult: previewResult,
                                  ),
                                ],
                              ),
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Loads the heroes of a nameless room so its display name resolves, then
/// builds again. The load runs once per row and again only when the room,
/// its name, its membership or its heroes change: the list rebuilds the row
/// on every sync, and each load can read the database or the server.
class _HeroUsersLoader extends StatefulWidget {
  const _HeroUsersLoader({required this.room, required this.builder});

  final Room room;
  final Widget Function(BuildContext context) builder;

  @override
  State<_HeroUsersLoader> createState() => _HeroUsersLoaderState();
}

class _HeroUsersLoaderState extends State<_HeroUsersLoader> {
  static const _heroesEquality = ListEquality<String>();

  Future<List<User>>? _heroUsers;
  String? _loadedRoomId;
  bool? _loadedNameless;
  Membership? _loadedMembership;
  List<String>? _loadedHeroes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _HeroUsersLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final room = widget.room;
    final nameless = room.name.isEmpty;
    if (room.id != _loadedRoomId ||
        nameless != _loadedNameless ||
        room.membership != _loadedMembership ||
        (nameless &&
            !_heroesEquality.equals(room.summary.mHeroes, _loadedHeroes))) {
      _load();
    }
  }

  void _load() {
    final room = widget.room;
    final nameless = room.name.isEmpty;
    _loadedRoomId = room.id;
    _loadedNameless = nameless;
    _loadedMembership = room.membership;
    // A copy: the display name adds the DM peer to empty heroes in place.
    _loadedHeroes = nameless ? room.summary.mHeroes?.toList() : null;
    _heroUsers = nameless ? room.loadHeroUsers() : null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _heroUsers,
      builder: (context, _) => widget.builder(context),
    );
  }
}

class _ChatListAvatar extends StatelessWidget {
  const _ChatListAvatar({
    required this.room,
    required this.name,
    required this.size,
    this.onTap,
  });

  final Room room;
  final String name;
  final double size;
  final VoidCallback? onTap;

  AvatarKindBadge? get _badge {
    if (room.isDirectChat) return null;
    if (room.isFeed) return AvatarKindBadge.broadcast;
    return room.joinRules == JoinRules.public
        ? AvatarKindBadge.public
        : AvatarKindBadge.people;
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    if (badge == null || room.isSpace) {
      return Avatar(
        mxContent: room.avatar,
        name: name,
        size: size,
        onTap: onTap,
        keepAlive: true,
        cornerRadius: room.isSpace ? size / 4 : null,
      );
    }
    return AvatarWithKindBadge(
      badge: badge,
      mxContent: room.avatar,
      name: name,
      size: size,
      onTap: onTap,
      keepAlive: true,
    );
  }
}
