import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/public_rooms/public_room_open_message.dart';
import 'package:twake_chat/pages/public_rooms/public_room_row.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_controller.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';
import 'package:twake_chat/pages/search/search_view_style.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';

/// The public groups the server finds for [searchTerm]. Nothing shows while
/// loading, on error or when none is found.
class PublicGroupsSearchSection extends StatelessWidget {
  const PublicGroupsSearchSection({
    super.key,
    required this.searchTerm,
    required this.header,
  });

  final ValueListenable<String?> searchTerm;

  final Widget header;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: searchTerm,
    builder: (context, term, _) => term == null
        ? const SliverToBoxAdapter(child: SizedBox.shrink())
        : _PublicGroupsSliver(searchTerm: term, header: header),
  );
}

/// Shows [child] unless public groups are found, or still asked, for
/// [searchTerm].
class HiddenWhenPublicGroupsFound extends StatelessWidget {
  const HiddenWhenPublicGroupsFound({
    super.key,
    required this.searchTerm,
    required this.child,
  });

  final ValueListenable<String?> searchTerm;

  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: searchTerm,
    builder: (context, term, child) => term == null
        ? child!
        : Consumer(
            builder: (context, ref, child) =>
                switch (_watchPublicGroups(ref, term)) {
                  AsyncLoading() => const SizedBox.shrink(),
                  AsyncData(:final value) when value.rooms.isNotEmpty =>
                    const SizedBox.shrink(),
                  _ => child!,
                },
            child: child,
          ),
    child: child,
  );
}

AsyncValue<PublicRoomsState>? _watchPublicGroups(
  WidgetRef ref,
  String searchTerm,
) {
  final isEnabled = ref.watch(
    loginHomeserverSummaryProvider.select(
      (summary) => summary.isPublicGroupsEnabled,
    ),
  );
  if (!isEnabled) return null;
  return ref.watch(publicRoomsControllerProvider(searchTerm: searchTerm));
}

class _PublicGroupsSliver extends ConsumerWidget {
  const _PublicGroupsSliver({required this.searchTerm, required this.header});

  final String searchTerm;

  final Widget header;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    PublicRoom room,
  ) async {
    final l10n = L10n.of(context)!;
    final result = await ref
        .read(publicRoomsControllerProvider(searchTerm: searchTerm).notifier)
        .open(room);
    if (!context.mounted) return;
    if (result.message(l10n, room) case final message?) {
      TwakeSnackBar.show(context, message);
    }
    if (result case PublicRoomJoined(:final roomId)) {
      RoomRoute(roomid: roomId).go(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _watchPublicGroups(ref, searchTerm)?.value;
    if (state == null || state.rooms.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverMainAxisGroup(
      slivers: [
        header,
        if (state.pendingRoomId != null)
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(minHeight: 2),
          ),
        SliverPadding(
          padding: SearchViewStyle.paddingRecentChats,
          sliver: SliverList.builder(
            itemCount: state.rooms.length,
            itemBuilder: (context, index) {
              final room = state.rooms[index];
              final isRequested = state.requestedRoomIds.contains(room.roomId);
              return PublicRoomRow(
                key: ValueKey('public_group_${room.roomId}'),
                room: room,
                isRequested: isRequested,
                onTap: isRequested
                    ? null
                    : () => unawaited(_open(context, ref, room)),
              );
            },
          ),
        ),
      ],
    );
  }
}
