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
  static const _lookupBatchSize = 5;

  // One lookup at a time across pages, so the batch size holds overall.
  Future<void> _lookups = Future<void>.value();

  @override
  Future<PublicRoomsState> build({String? searchTerm}) async {
    final pages = StreamIterator(
      ref
          .watch(fetchJoinablePublicRoomsUseCaseProvider)
          .execute(searchTerm: searchTerm),
    );
    ref.onDispose(() => unawaited(pages.cancel()));
    final hasFirstPage = await pages.moveNext();
    if (!ref.mounted || !hasFirstPage) return const PublicRoomsState(rooms: []);
    final loadedIds = <String>{};
    final firstPage = pages.current
        .where((room) => loadedIds.add(room.roomId))
        .toList();
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
            requestedRoomIds: {...state.requestedRoomIds, room.roomId},
          ),
        );
        return const PublicRoomRequested();
      }
      final joined = await ref
          .read(joinPublicRoomUseCaseProvider)
          .execute(room.roomId);
      if (ref.mounted) {
        _update(
          (state) => state.copyWith(
            rooms: [
              for (final other in state.rooms)
                if (other.roomId != room.roomId) other,
            ],
          ),
        );
      }
      return joined.isInSync
          ? PublicRoomJoined(joined.roomId)
          : const PublicRoomJoinedNotInSync();
    } on PublicRoomsException {
      return const PublicRoomOpenFailed();
    } finally {
      if (ref.mounted) {
        _update((state) => state.copyWith(pendingRoomId: null));
      }
    }
  }

  Future<void> _loadMore(
    List<PublicRoom> firstPage,
    StreamIterator<List<PublicRoom>> pages,
  ) async {
    await future;
    if (!ref.mounted) return;
    _queueLookup(firstPage);
    try {
      while (await pages.moveNext()) {
        if (!ref.mounted) return;
        final loadedIds = {
          for (final room in state.value?.rooms ?? const <PublicRoom>[])
            room.roomId,
        };
        final added = pages.current
            .where((room) => loadedIds.add(room.roomId))
            .toList();
        _update((state) => state.copyWith(rooms: [...state.rooms, ...added]));
        _queueLookup(added);
      }
    } on PublicRoomsException {
      // Logged by the datasource: keep the rooms already shown.
    } finally {
      if (ref.mounted) {
        _update((state) => state.copyWith(isLoadingMore: false));
      }
    }
  }

  void _queueLookup(List<PublicRoom> page) {
    // An untyped error still surfaces, but the next pages are looked up.
    _lookups = _lookups
        .then((_) => _markRequested(page))
        .onError<Object>(Zone.current.handleUncaughtError);
  }

  Future<void> _markRequested(List<PublicRoom> page) async {
    final roomIds = [
      for (final room in page)
        if (room.access == PublicRoomAccess.approval) room.roomId,
    ];
    for (var start = 0; start < roomIds.length; start += _lookupBatchSize) {
      if (!ref.mounted) return;
      final batch = roomIds.skip(start).take(_lookupBatchSize).toList();
      final Set<String> requested;
      try {
        requested = await ref
            .read(getKnockedPublicRoomIdsUseCaseProvider)
            .execute(batch);
      } on PublicRoomsException {
        return;
      }
      if (!ref.mounted) return;
      if (requested.isEmpty) continue;
      _update(
        (state) => state.copyWith(
          requestedRoomIds: {...state.requestedRoomIds, ...requested},
        ),
      );
    }
  }

  void _update(PublicRoomsState Function(PublicRoomsState state) change) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(change(current));
  }
}
