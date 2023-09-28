import 'package:collection/collection.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:matrix/matrix.dart';

extension ClientExtension on Client {
  static const int _ascendingOrder = 1;

  static const int _descendingOrder = -1;

  int _sortListRomByTimeCreatedMessage(Room currentRoom, Room nextRoom) {
    return nextRoom.timeCreated.compareTo(currentRoom.timeCreated);
  }

  int _sortListRoomByPinMessage(Room currentRoom, Room nextRoom) {
    if (nextRoom.isFavourite && !currentRoom.isFavourite) {
      return _ascendingOrder;
    } else {
      return _descendingOrder;
    }
  }

  List<Room> filteredRoomsForAll(ActiveFilter activeFilter) {
    return rooms
        .where(activeFilter.getRoomFilterByActiveFilter())
        .sorted(_sortListRomByTimeCreatedMessage)
        .sorted(_sortListRoomByPinMessage)
        .toList();
  }
}
