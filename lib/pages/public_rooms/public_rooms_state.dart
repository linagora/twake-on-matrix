import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/utils/search/search_options.dart';

part 'public_rooms_state.freezed.dart';

@freezed
abstract class PublicRoomsState with _$PublicRoomsState {
  const PublicRoomsState._();

  const factory PublicRoomsState({
    required List<PublicRoom> rooms,
    @Default({}) Set<String> requestedRoomIds,
    @Default(false) bool isLoadingMore,
    String? pendingRoomId,
  }) = _PublicRoomsState;

  static const _searchOptions = SearchOptions(diacriticSensitive: false);

  /// The rooms whose name contains [query], ignoring case and accents.
  List<PublicRoom> roomsMatching(String query) =>
      const SearchEngine().matchAnyField(
        query.trim(),
        rooms,
        fieldExtractors: [
          (room) => [room.name],
        ],
        options: _searchOptions,
      );
}

sealed class PublicRoomOpenResult {
  const PublicRoomOpenResult();
}

class PublicRoomJoined extends PublicRoomOpenResult {
  const PublicRoomJoined(this.roomId);

  final String roomId;
}

class PublicRoomRequested extends PublicRoomOpenResult {
  const PublicRoomRequested();
}

class PublicRoomOpenFailed extends PublicRoomOpenResult {
  const PublicRoomOpenFailed();
}

/// Busy with another room, or a request is already pending: the tap is
/// ignored.
class PublicRoomOpenIgnored extends PublicRoomOpenResult {
  const PublicRoomOpenIgnored();
}
