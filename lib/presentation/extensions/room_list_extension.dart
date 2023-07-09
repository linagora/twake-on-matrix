import 'package:fluffychat/presentation/extensions/room_extension.dart';
import 'package:fluffychat/presentation/model/presentation_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:matrix/matrix.dart';

extension RoomListExtension on List<Room> {
  List<PresentationSearch> toPresentationSearchList(BuildContext context) {
    return map((room) => room.toPresentationSearch(context)).toList();
  }
}