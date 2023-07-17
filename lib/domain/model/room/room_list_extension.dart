import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/model/search/search_model.dart';
import 'package:matrix/matrix.dart';

extension RoomListExtension on List<Room> {
  List<SearchModel> toSearchList(MatrixLocalizations matrixLocalizations) {
    return map((room) => room.toSearch(matrixLocalizations)).toList();
  }
}