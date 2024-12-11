import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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

  bool isDisplayableResult({
    BuildContext? context,
    required String searchWord,
  }) {
    if (context == null) {
      return false;
    }
    final event = getEvent(context);
    if (event == null) {
      return false;
    }
    final bodyContent = event.calcLocalizedBodyFallback(
      MatrixLocals(L10n.of(context)!),
      hideEdit: true,
      hideReply: true,
      plaintextBody: true,
      removeMarkdown: true,
    );

    return bodyContent.toLowerCase().contains(searchWord.toLowerCase());
  }
}
