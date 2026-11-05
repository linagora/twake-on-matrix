import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';
import 'package:twake_chat/domain/repository/public_rooms/public_rooms_repository.dart';

class GetPublicRoomPreviewUseCase {
  const GetPublicRoomPreviewUseCase(this._repository);

  final PublicRoomsRepository _repository;

  /// Throws a `PublicRoomsNoClientException`.
  Future<PublicRoomPreview> execute(
    String roomIdOrAlias, {
    List<String> via = const [],
  }) => _repository.getPreview(roomIdOrAlias, via: via);
}
