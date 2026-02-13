import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/exception/leave_room_exception.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

mixin LeaveChatMixin {
  Future<void> leaveChat(BuildContext context, Room? room) async {
    try {
      if (room == null) {
        throw RoomNullException();
      }

      final confirmResult = await showConfirmAlertDialog(
        context: context,
        title: L10n.of(context)!.leaveChatTitle,
        message: L10n.of(context)!.leaveChatDescription,
        okLabel: L10n.of(context)!.leave,
        cancelLabel: L10n.of(context)!.cancel,
        showCloseButton: PlatformInfos.isWeb,
      );
      if (confirmResult == ConfirmResult.cancel) return;

      final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: room.leave,
      );

      if (result.error != null) return;

      // For DMs the room would otherwise linger in the sidebar as a ghost
      // until the next sync cycle; forget it immediately so it disappears.
      if (room.isDirectChat) {
        try {
          await room.client.forgetRoom(room.id);
        } catch (e) {
          Logs().e('LeaveChatMixin::leaveChat(): forgetRoom failed - $e');
        }
      }

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
