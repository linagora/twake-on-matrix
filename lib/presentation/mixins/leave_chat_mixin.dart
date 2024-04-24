import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/exception/leave_room_exception.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

mixin LeaveChatMixin {
  Future<void> leaveChat(BuildContext context, Room? room) async {
    try {
      if (room == null) {
        throw RoomNullException();
      }

      final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: room.leave,
      );

      if (result.error != null) return;

      context.go('/rooms');
    } on RoomNullException catch (e) {
      Logs().e('LeaveChatMixin::leaveChat(): - RoomNullException - $e');
      TwakeSnackBar.show(context, L10n.of(context)!.leaveChatFailed);
    } catch (e) {
      Logs().e('LeaveChatMixin::leaveChat(): - error: $e');
      TwakeSnackBar.show(context, L10n.of(context)!.leaveChatFailed);
    }
  }
}
