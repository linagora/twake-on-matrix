import 'dart:async';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/unblock_user_state.dart';
import 'package:fluffychat/domain/usecase/room/unblock_user_interactor.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

mixin UnblockUserMixin {
  final unblockUserInteractor = getIt.get<UnblockUserInteractor>();

  StreamSubscription? unblockUserSubscription;

  Future<void> onTapUnblockUser({
    required BuildContext context,
    required Client client,
    required String displayName,
    required String userID,
  }) async {
    final confirmResult = await showConfirmAlertDialog(
      context: context,
      title: L10n.of(context)!.unblockUsername(displayName),
      message: L10n.of(context)!.unblockDescriptionDialog,
      okLabel: L10n.of(context)!.unblock,
      cancelLabel: L10n.of(context)!.cancel,
      showCloseButton: PlatformInfos.isWeb,
    );
    if (confirmResult == ConfirmResult.cancel) return;
    unblockUserSubscription = unblockUserInteractor
        .execute(client: client, userId: userID)
        .listen(
          (event) => event.fold(
            (failure) {
              if (failure is UnblockUserFailure) {
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(context, failure.exception.toString());
                return;
              }

              if (failure is NoPermissionForUnblockFailure) {
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.permissionErrorUnblockUser,
                );
                return;
              }

              if (failure is NotValidMxidUnblockFailure) {
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.userIsNotAValidMxid(userID),
                );
                return;
              }

              if (failure is NotInTheIgnoreListFailure) {
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.userNotFoundInIgnoreList(userID),
                );
                return;
              }
            },
            (success) {
              if (success is UnblockUserLoading) {
                TwakeDialog.showLoadingDialog(context);
                return;
              }
              if (success is UnblockUserSuccess) {
                TwakeDialog.hideLoadingDialog(context);
                return;
              }
            },
          ),
        );
  }

  void disposeUnblockUserSubscription() {
    unblockUserSubscription?.cancel();
    unblockUserSubscription = null;
  }
}
