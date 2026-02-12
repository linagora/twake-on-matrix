import 'dart:async';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/delete_event_state.dart';
import 'package:fluffychat/domain/usecase/room/delete_event_interactor.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

mixin DeleteEventMixin {
  final deleteEventInteractor = getIt.get<DeleteEventInteractor>();
  StreamSubscription? _streamSubscription;

  Future<void> deleteEventAction(BuildContext context, Event event) async {
    final confirmResult = await showConfirmAlertDialog(
      context: context,
      title: L10n.of(context)!.deleteMessageConfirmationTitle,
      okLabel: L10n.of(context)!.delete,
      cancelLabel: L10n.of(context)!.cancel,
      showCloseButton: PlatformInfos.isWeb,
    );
    if (confirmResult == ConfirmResult.cancel) return;
    _streamSubscription = deleteEventInteractor.execute(event).listen((state) {
      state.fold((failure) {
        if (failure is NoPermissionToDeleteEvent) {
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.noDeletePermissionMessage,
          );
          return;
        }
        TwakeSnackBar.show(context, L10n.of(context)!.failedToDeleteMessage);
      }, (success) {});
    });
  }

  void disposeDeleteEventMixin() {
    _streamSubscription?.cancel();
  }
}
