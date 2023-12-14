import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

extension ResultExtension on Result {
  Event? getEvent(BuildContext context) {
    if (result?.roomId == null) {
      return null;
    }
    final room = Matrix.of(context).client.getRoomById(result!.roomId!);
    if (room == null) {
      return null;
    }
    return Event.fromMatrixEvent(result!, room);
  }
}
