import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/empty_state/linagora_empty_state.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/public_rooms/public_room_open_message.dart';
import 'package:twake_chat/pages/public_rooms/public_room_row.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_controller.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';
import 'package:twake_chat/pages/search/search_text_field.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
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
        .read(publicRoomsControllerProvider().notifier)
        .open(room);
    if (!mounted) return;
    if (result.message(l10n, room) case final message?) {
      TwakeSnackBar.show(context, message);
    }
    switch (result) {
      case PublicRoomJoined(:final roomId):
        context.pop();
        RoomRoute(roomid: roomId).go(context);
      case PublicRoomJoinedNotInSync():
        context.pop();
      case PublicRoomRequested() ||
          PublicRoomOpenFailed() ||
          PublicRoomOpenIgnored():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final state = ref.watch(publicRoomsControllerProvider());
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
            isLoadingMore: value.isLoadingMore,
            requestedRoomIds: value.requestedRoomIds,
            onOpen: (room) => unawaited(_open(room)),
          ),
        ),
        AsyncError() => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ref.invalidate(publicRoomsControllerProvider()),
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
              onTap: () => context.pop(),
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
    required this.isLoadingMore,
    required this.requestedRoomIds,
    required this.onOpen,
  });

  // Same insets as the chat list rows.
  static const _padding = EdgeInsets.symmetric(horizontal: 8);

  final List<PublicRoom> rooms;
  final bool isDirectoryEmpty;
  final bool isLoadingMore;
  final Set<String> requestedRoomIds;
  final ValueChanged<PublicRoom> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    // The next pages may still bring a match: the progress bar is enough.
    if (rooms.isEmpty && isLoadingMore) return const SizedBox.shrink();
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
        return PublicRoomRow(
          key: ValueKey(room.roomId),
          room: room,
          isRequested: isRequested,
          onTap: isRequested ? null : () => onOpen(room),
        );
      },
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
