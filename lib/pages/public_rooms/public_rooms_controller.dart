import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/public_rooms/usecases/fetch_joinable_public_rooms_usecase.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/get_knocked_public_room_ids_usecase.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/join_public_room_usecase.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/knock_public_room_usecase.provider.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';

part 'public_rooms_controller.g.dart';

@riverpod
class PublicRoomsController extends _$PublicRoomsController {
  @override
  Future<PublicRoomsState> build() async {
    final pages = StreamIterator(
      ref.watch(fetchJoinablePublicRoomsUseCaseProvider).execute(),
    );
    ref.onDispose(() => unawaited(pages.cancel()));
    final hasFirstPage = await pages.moveNext();
    if (!ref.mounted || !hasFirstPage) return const PublicRoomsState(rooms: []);
    final firstPage = pages.current;
    unawaited(_loadMore(firstPage, pages));
    return PublicRoomsState(rooms: firstPage, isLoadingMore: true);
  }

  Future<PublicRoomOpenResult> open(PublicRoom room) async {
    final current = state.value;
    if (current == null || !current.canOpen(room.roomId)) {
      return const PublicRoomOpenIgnored();
    }
    state = AsyncData(current.copyWith(pendingRoomId: room.roomId));
    try {
      if (room.access == PublicRoomAccess.approval) {
        await ref.read(knockPublicRoomUseCaseProvider).execute(room.roomId);
        if (!ref.mounted) return const PublicRoomRequested();
        _update(
          (state) => state.copyWith(
            pendingRoomId: null,
            requestedRoomIds: {...state.requestedRoomIds, room.roomId},
          ),
        );
        return const PublicRoomRequested();
      }
      final roomId = await ref
          .read(joinPublicRoomUseCaseProvider)
          .execute(room.roomId);
      if (!ref.mounted) return PublicRoomJoined(roomId);
      _update((state) => state.copyWith(pendingRoomId: null));
      return PublicRoomJoined(roomId);
    } on PublicRoomsException {
      if (ref.mounted) {
        _update((state) => state.copyWith(pendingRoomId: null));
      }
      return const PublicRoomOpenFailed();
    }
  }

  Future<void> _loadMore(
    List<PublicRoom> firstPage,
    StreamIterator<List<PublicRoom>> pages,
  ) async {
    await future;
    if (!ref.mounted) return;
    unawaited(_markRequested(firstPage));
    try {
      while (await pages.moveNext()) {
        if (!ref.mounted) return;
        final page = pages.current;
        _update((state) => state.copyWith(rooms: [...state.rooms, ...page]));
        unawaited(_markRequested(page));
      }
    } on PublicRoomsException {
      // Logged by the datasource: keep the rooms already shown.
    }
    if (!ref.mounted) return;
    _update((state) => state.copyWith(isLoadingMore: false));
  }

  Future<void> _markRequested(List<PublicRoom> page) async {
    final roomIds = [
      for (final room in page)
        if (room.access == PublicRoomAccess.approval) room.roomId,
    ];
    if (roomIds.isEmpty) return;
    final Set<String> requested;
    try {
      requested = await ref
          .read(getKnockedPublicRoomIdsUseCaseProvider)
          .execute(roomIds);
    } on PublicRoomsException {
      return;
    }
    if (!ref.mounted || requested.isEmpty) return;
    _update(
      (state) => state.copyWith(
        requestedRoomIds: {...state.requestedRoomIds, ...requested},
      ),
    );
  }

  void _update(PublicRoomsState Function(PublicRoomsState state) change) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(change(current));
  }
}
