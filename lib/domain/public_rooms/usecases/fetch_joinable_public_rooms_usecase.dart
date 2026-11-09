import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/repository/public_rooms/public_rooms_repository.dart';

class FetchJoinablePublicRoomsUseCase {
  const FetchJoinablePublicRoomsUseCase(this._repository);

  static const directoryLimit = 1000;

  static const searchLimit = 20;

  static const minSearchLength = 2;

  static const _listedKinds = {PublicRoomKind.group, PublicRoomKind.feed};

  final PublicRoomsRepository _repository;

  /// The groups and feeds of the homeserver directory the user has neither
  /// joined nor been invited to, one page at a time. With [searchTerm], the
  /// first [searchLimit] rooms the server matches, trimmed; nothing under
  /// [minSearchLength] letters. Throws a `PublicRoomsFetchFailedException`
  /// when the first page fails.
  Stream<List<PublicRoom>> execute({String? searchTerm}) async* {
    final term = searchTerm?.trim();
    if (term != null && term.length < minSearchLength) return;
    await for (final page in _repository.fetchDirectory(
      limit: term == null ? directoryLimit : searchLimit,
      searchTerm: term,
    )) {
      final members = _repository.getKnownRoomIds();
      yield page
          .where(
            (room) =>
                _listedKinds.contains(room.kind) &&
                !members.contains(room.roomId),
          )
          .toList();
    }
  }
}
