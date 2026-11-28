import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/domain/model/room/room_preview_result.dart';
import 'package:twake_chat/presentation/mixins/chat_list_item_mixin.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list_row_divider.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_title.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/space_row_actions.dart';
import 'package:twake_chat/presentation/model/chat_list/space_row_data.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/avatar/avatar_with_kind_badge.dart';
import 'package:twake_chat/widgets/avatar/avatar_style.dart';
import 'package:twake_chat/widgets/avatar/person_presence_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/providers/personalization/display_preferences_controller.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

enum ArchivedRoomAction { delete, rejoin }

class ChatListItem extends ConsumerWidget with ChatListItemMixin {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isChild = depth > 0;
    final compact = ref.watch(
      displayPreferencesProvider.select(
        (preferences) => preferences.density == ChatListDensity.compact,
      ),
    );
    final bodyPadding = compact
        ? ChatListItemStyle.compactPaddingBody
        : ChatListItemStyle.paddingBody;
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
              height: space != null && isChild
                  ? ChatListItemStyle.spaceItemHeight
                  : compact
                  ? null
                  : ChatListItemStyle.chatItemHeight,
              // A compact group row shows three lines: it grows past the
              // minimum instead of overflowing.
              constraints: space == null && compact
                  ? const BoxConstraints(
                      minHeight: ChatListItemStyle.compactChatItemHeight,
                    )
                  : null,
              padding: bodyPadding.add(
                EdgeInsetsDirectional.only(
                  start: depth * ChatListItemStyle.depthIndent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isEnableSelectMode) checkBoxWidget ?? const SizedBox(),
                  Padding(
                    padding: ChatListItemStyle.paddingAvatar,
                    child: _ChatListAvatar(
                      room: room,
                      name: displayName,
                      size: isChild
                          ? ChatListItemStyle.childAvatarSize
                          : compact
                          ? ChatListItemStyle.compactAvatarSize
                          : AvatarStyle.defaultSize,
                      onTap: onTapAvatar,
                    ),
                  ),
                  Expanded(
                    child: ChatListRowDivider(
                      bottomInset: bodyPadding.bottom,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: space == null && compact
                              ? ChatListItemStyle.compactChatItemHeight -
                                    bodyPadding.vertical
                              : 0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: space == null && compact
                                    ? MainAxisSize.min
                                    : MainAxisSize.max,
                                mainAxisAlignment: space != null
                                    ? MainAxisAlignment.center
                                    : MainAxisAlignment.start,
                                children: [
                                  ChatListItemTitle(
                                    room: room,
                                    originServerTs: switch (previewResult) {
                                      RoomPreviewFound(:final event)
                                          when space == null =>
                                        event.originServerTs,
                                      _ => null,
                                    },
                                  ),
                                  // A space is no conversation: nothing to preview.
                                  if (space == null)
                                    ChatListItemSubtitle(
                                      room: room,
                                      previewResult: previewResult,
                                    )
                                  else if (room.isInvitation)
                                    Text(
                                      L10n.of(context)!.invited,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: LinagoraSysColors.material()
                                                .primary,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            if (space case final space?)
                              SpaceRowActions(name: displayName, space: space),
                          ],
                        ),
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
    if (room.isSpace) return AvatarKindBadge.space;
    if (room.isFeed) return AvatarKindBadge.broadcast;
    return room.joinRules == JoinRules.public
        ? AvatarKindBadge.public
        : AvatarKindBadge.people;
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    if (badge == null) {
      final avatar = Avatar(
        mxContent: room.avatar,
        name: name,
        size: size,
        onTap: onTap,
        keepAlive: true,
      );
      final peerId = room.directChatMatrixID;
      if (peerId == null) return avatar;
      return PersonPresenceBadge(userId: peerId, size: size, child: avatar);
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
