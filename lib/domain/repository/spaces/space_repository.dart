import 'package:twake_chat/domain/spaces/new_space.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';

abstract class SpaceRepository {
  /// Ticks when the rooms change: what is read here may have too.
  Stream<int> watchRoomChanges();

  /// The rooms the room list may show, spaces included.
  List<RoomListEntry> getRoomListEntries();

  /// The home of a joined space, `null` for anything else.
  SpaceSummary? getSpace(String roomId);

  /// The spaces the user may add a room to.
  List<SpaceSummary> getAddableSpaces();

  /// The children of a space in their order.
  ///
  /// Throws a `SpaceChildrenUnavailableException`.
  Future<List<SpaceChannel>> getSpaceChildren(String spaceId);

  /// Throws a `SpaceJoinFailedException`.
  Future<void> joinRoom(String roomId, {List<String> via = const []});

  /// Loads the whole state of the space and marks it read.
  Future<void> open(String roomId);

  /// Creates the space and lists it in its parent.
  ///
  /// Throws a `SpaceException`.
  Future<String> createSpace(NewSpace space);
}
