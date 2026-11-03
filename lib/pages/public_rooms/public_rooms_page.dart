import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/empty_state/linagora_empty_state.dart';
import 'package:linagora_design_flutter/list_item/linagora_avatar_list_item.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_controller.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';
import 'package:twake_chat/pages/search/search_text_field.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/avatar/avatar_with_kind_badge.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

class PublicRoomsPage extends ConsumerStatefulWidget {
  const PublicRoomsPage({super.key});

  @override
  ConsumerState<PublicRoomsPage> createState() => _PublicRoomsPageState();
}

class _PublicRoomsPageState extends ConsumerState<PublicRoomsPage> {
  // Same end inset as the chat list search field.
  static const _searchFieldPadding = EdgeInsetsDirectional.only(end: 8);

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _open(PublicRoom room) async {
    final l10n = L10n.of(context)!;
    final result = await ref
        .read(publicRoomsControllerProvider.notifier)
        .open(room);
    if (!mounted) return;
    switch (result) {
      case PublicRoomJoined(:final roomId):
        Navigator.of(context).pop();
        RoomRoute(roomid: roomId).go(context);
      case PublicRoomJoinedNotInSync():
        TwakeSnackBar.show(context, l10n.youJoinedTheChat);
        Navigator.of(context).pop();
      case PublicRoomRequested():
        TwakeSnackBar.show(context, l10n.joinRequestSentAdminMustApprove);
      case PublicRoomOpenFailed():
        TwakeSnackBar.show(
          context,
          room.access == PublicRoomAccess.approval
              ? l10n.publicGroupRequestFailed
              : l10n.publicGroupJoinFailed,
        );
      case PublicRoomOpenIgnored():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final state = ref.watch(publicRoomsControllerProvider);
    return Scaffold(
      appBar: _buildAppBar(
        isBusy:
            state.value?.pendingRoomId != null ||
            (state.value?.isLoadingMore ?? false),
      ),
      body: switch (state) {
        AsyncData(:final value) => ValueListenableBuilder(
          valueListenable: _searchController,
          builder: (context, query, _) => _PublicRoomList(
            rooms: value.roomsMatching(query.text),
            isDirectoryEmpty: value.rooms.isEmpty,
            requestedRoomIds: value.requestedRoomIds,
            onOpen: (room) => unawaited(_open(room)),
          ),
        ),
        AsyncError() => GestureDetector(
          onTap: () => ref.invalidate(publicRoomsControllerProvider),
          child: _PublicRoomsEmptyState(
            title: l10n.publicGroupsLoadFailed,
            description: l10n.tapToRetry,
          ),
        ),
        _ => Center(
          child: CircularProgressIndicator(semanticsLabel: l10n.publicGroups),
        ),
      },
    );
  }

  PreferredSizeWidget _buildAppBar({required bool isBusy}) {
    final l10n = L10n.of(context)!;
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 8,
      title: Padding(
        padding: _searchFieldPadding,
        child: Row(
          children: [
            TwakeIconButton(
              tooltip: l10n.back,
              icon: Icons.arrow_back_ios,
              onTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SearchTextField(
                textEditingController: _searchController,
                hintText: l10n.searchPublicGroups,
              ),
            ),
          ],
        ),
      ),
      bottom: isBusy
          ? const PreferredSize(
              preferredSize: Size.fromHeight(2),
              child: LinearProgressIndicator(minHeight: 2),
            )
          : null,
    );
  }
}

class _PublicRoomList extends StatelessWidget {
  const _PublicRoomList({
    required this.rooms,
    required this.isDirectoryEmpty,
    required this.requestedRoomIds,
    required this.onOpen,
  });

  // Same insets as the chat list rows.
  static const _padding = EdgeInsets.symmetric(horizontal: 8);

  final List<PublicRoom> rooms;
  final bool isDirectoryEmpty;
  final Set<String> requestedRoomIds;
  final ValueChanged<PublicRoom> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    if (rooms.isEmpty) {
      return _PublicRoomsEmptyState(
        title: isDirectoryEmpty
            ? l10n.noPublicGroupToJoin
            : l10n.noPublicGroupMatchesSearch,
      );
    }
    return ListView.builder(
      padding: _padding,
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final isRequested = requestedRoomIds.contains(room.roomId);
        return _PublicRoomRow(
          key: ValueKey(room.roomId),
          room: room,
          isRequested: isRequested,
          onTap: isRequested ? null : () => onOpen(room),
        );
      },
    );
  }
}

class _PublicRoomRow extends StatelessWidget {
  const _PublicRoomRow({
    super.key,
    required this.room,
    required this.isRequested,
    required this.onTap,
  });

  final PublicRoom room;
  final bool isRequested;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final access = isRequested
        ? l10n.publicGroupRequestSentMembers(room.memberCount)
        : room.access == PublicRoomAccess.approval
        ? l10n.askToJoinPublicGroupMembers(room.memberCount)
        : l10n.joinPublicGroupMembers(room.memberCount);
    final topic = room.topic;
    return LinagoraAvatarListItem(
      avatar: AvatarWithKindBadge(
        mxContent: room.avatarUri,
        name: room.name,
        badge: switch (room) {
          PublicRoom(kind: PublicRoomKind.feed) => AvatarKindBadge.broadcast,
          PublicRoom(access: PublicRoomAccess.open) => AvatarKindBadge.public,
          _ => AvatarKindBadge.people,
        },
      ),
      title: room.name,
      subtitle: topic == null || topic.isEmpty ? access : '$access · $topic',
      onTap: onTap,
    );
  }
}

class _PublicRoomsEmptyState extends StatelessWidget {
  const _PublicRoomsEmptyState({required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LinagoraEmptyState(
        compact: true,
        illustration: SvgPicture.asset(Assets.images.icEmptySearch.path),
        title: title,
        description: description,
      ),
    ),
  );
}
