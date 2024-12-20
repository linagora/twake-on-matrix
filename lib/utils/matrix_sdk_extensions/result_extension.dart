import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

extension ResultExtension on Result {
  Event? getEvent(BuildContext? context) {
    if (context == null) {
      return null;
    }
    if (result?.roomId == null) {
      return null;
    }
    final room = Matrix.of(context).client.getRoomById(result!.roomId!);
    if (room == null) {
      return null;
    }
    return Event.fromMatrixEvent(result!, room);
  }

  bool isDisplayableResult({
    BuildContext? context,
    Event? event,
    required String searchWord,
    required MatrixLocalizations matrixLocalizations,
  }) {
    if (context == null) {
      return false;
    }
    if (event == null) {
      return false;
    }
    final bodyContent = event.calcLocalizedBodyFallback(
      matrixLocalizations,
      hideEdit: true,
      hideReply: true,
      plaintextBody: true,
      removeMarkdown: true,
    );

    return bodyContent.toLowerCase().contains(searchWord.toLowerCase());
  }
}
