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
    final current = state.value;
    final preview = current?.preview;
    if (current == null ||
        current.isPending ||
        preview is PublicRoomPreviewBanned ||
        preview is PublicRoomPreviewJoined ||
        preview is PublicRoomPreviewFound && preview.isRequested) {
      return const PublicRoomOpenIgnored();
    }
    state = AsyncData(current.copyWith(isPending: true, hasFailed: false));
    try {
      if (preview case PublicRoomPreviewFound(
        room: PublicRoom(access: PublicRoomAccess.approval),
      )) {
        await ref
            .read(knockPublicRoomUseCaseProvider)
            .execute(address.roomIdOrAlias, via: address.via);
        if (!ref.mounted) return const PublicRoomRequested();
        _update(
          (state) =>
              state.copyWith(preview: preview.copyWith(isRequested: true)),
        );
        return const PublicRoomRequested();
      }
      final joined = await ref
          .read(joinPublicRoomUseCaseProvider)
          .execute(address.roomIdOrAlias, via: address.via);
      if (!ref.mounted) return const PublicRoomOpenIgnored();
      return joined.isInSync
          ? PublicRoomJoined(joined.roomId)
          : const PublicRoomJoinedNotInSync();
    } on PublicRoomsException {
      if (ref.mounted) _update((state) => state.copyWith(hasFailed: true));
      return const PublicRoomOpenFailed();
    } finally {
      if (ref.mounted) _update((state) => state.copyWith(isPending: false));
    }
  }

  void _update(PublicRoomPreviewState Function(PublicRoomPreviewState) change) {
    if (state.value case final current?) state = AsyncData(change(current));
  }
}
