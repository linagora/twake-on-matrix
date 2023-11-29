import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

extension MatrixEventExtension on MatrixEvent {
  Room? getRoom(BuildContext context) {
    if (roomId == null) {
      return null;
    }
    return Matrix.of(context).client.getRoomById(roomId!);
  }
}
