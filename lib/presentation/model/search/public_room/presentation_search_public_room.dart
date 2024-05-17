import 'package:fluffychat/presentation/model/search/public_room/presentation_search_public_room_state.dart';
import 'package:matrix/matrix.dart';

class PresentationSearchPublicRoom extends PresentationSearchPublicRoomUIState {
  final List<PublicRoomsChunk> searchResults;

  PresentationSearchPublicRoom({
    required this.searchResults,
  });

  @override
  List<Object> get props => [searchResults];
}
