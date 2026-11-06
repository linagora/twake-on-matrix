import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';
import 'package:twake_chat/domain/model/public_rooms/room_address.dart';
import 'package:twake_chat/domain/public_rooms/usecases/get_public_room_preview_usecase.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/join_public_room_usecase.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/knock_public_room_usecase.provider.dart';
import 'package:twake_chat/pages/public_rooms/preview/public_room_preview_state.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';

part 'public_room_preview_controller.g.dart';

@riverpod
class PublicRoomPreviewController extends _$PublicRoomPreviewController {
  @override
  Future<PublicRoomPreviewState> build(RoomAddress address) async {
    final preview = await ref
        .watch(getPublicRoomPreviewUseCaseProvider)
        .execute(address.roomIdOrAlias, via: address.via);
    return PublicRoomPreviewState(preview: preview);
  }

  /// Joins the room, or asks to join it when it needs an approval.
  Future<PublicRoomOpenResult> open() async {
    // A failed lookup shows « Try to join », as an unavailable preview.
    final current =
        state.value ??
        const PublicRoomPreviewState(preview: PublicRoomPreview.unavailable());
    if (!current.canOpen) {
      return const PublicRoomOpenIgnored();
    }
    state = AsyncData(current.copyWith(isPending: true, hasFailed: false));
    try {
      return switch (current.preview) {
        final PublicRoomPreviewFound preview
            when preview.room.access == PublicRoomAccess.approval =>
          await _knock(preview),
        _ => await _join(),
      };
    } on PublicRoomsException {
      if (ref.mounted) _update((state) => state.copyWith(hasFailed: true));
      return const PublicRoomOpenFailed();
    } finally {
      if (ref.mounted) _update((state) => state.copyWith(isPending: false));
    }
  }

  Future<PublicRoomOpenResult> _knock(PublicRoomPreviewFound preview) async {
    await ref
        .read(knockPublicRoomUseCaseProvider)
        .execute(address.roomIdOrAlias, via: address.via);
    if (ref.mounted) {
      _update(
        (state) => state.copyWith(preview: preview.copyWith(isRequested: true)),
      );
    }
    return const PublicRoomRequested();
  }

  Future<PublicRoomOpenResult> _join() async {
    final joined = await ref
        .read(joinPublicRoomUseCaseProvider)
        .execute(address.roomIdOrAlias, via: address.via);
    if (!ref.mounted) return const PublicRoomOpenIgnored();
    return joined.isInSync
        ? PublicRoomJoined(joined.roomId)
        : const PublicRoomJoinedNotInSync();
  }

  void _update(PublicRoomPreviewState Function(PublicRoomPreviewState) change) {
    if (state.value case final current?) state = AsyncData(change(current));
  }
}
