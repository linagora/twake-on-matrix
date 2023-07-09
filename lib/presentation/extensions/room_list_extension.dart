import 'package:fluffychat/presentation/extensions/room_extension.dart';
import 'package:fluffychat/presentation/model/presentation_search.dart';
import 'package:matrix/matrix.dart';

extension RoomListExtension on List<Room> {
  List<PresentationSearch> toPresentationSearchList(MatrixLocalizations matrixLocalizations) {
    return map((room) => room.toPresentationSearch(matrixLocalizations)).toList();
  }
}