import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/public_rooms/usecases/fetch_joinable_public_rooms_usecase.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/join_public_room_usecase.provider.dart';
import 'package:twake_chat/domain/public_rooms/usecases/knock_public_room_usecase.provider.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';

part 'public_rooms_controller.g.dart';

@riverpod
class PublicRoomsController extends _$PublicRoomsController {
  @override
  Future<PublicRoomsState> build() async {
    final rooms = await ref
        .watch(fetchJoinablePublicRoomsUseCaseProvider)
        .execute();
    return PublicRoomsState(rooms: rooms);
  }

  Future<PublicRoomOpenResult> open(PublicRoom room) async {
    final current = state.value;
    if (current == null || current.pendingRoomId != null) {
      return const PublicRoomOpenIgnored();
    }
    state = AsyncData(current.copyWith(pendingRoomId: room.roomId));
    final PublicRoomOpenResult result;
    try {
      if (room.access == PublicRoomAccess.approval) {
        await ref.read(knockPublicRoomUseCaseProvider).execute(room.roomId);
        result = const PublicRoomRequested();
      } else {
        final roomId = await ref
            .read(joinPublicRoomUseCaseProvider)
            .execute(room.roomId);
        result = PublicRoomJoined(roomId);
      }
    } on PublicRoomsException {
      if (ref.mounted) _clearPending();
      return const PublicRoomOpenFailed();
    }
    if (!ref.mounted) return result;
    _clearPending();
    return result;
  }

  void _clearPending() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(pendingRoomId: null));
  }
}
