import 'dart:async';

import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/room/delete_event_state.dart';
import 'package:twake_chat/domain/usecase/room/delete_event_interactor.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

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

  /// Deletes every image of an album after one confirmation.
  Future<void> deleteAlbumAction(
    BuildContext context,
    List<Event> events,
  ) async {
    // The bubble may be gone when the menu closes (its image was deleted).
    if (!context.mounted) return;
    final l10n = L10n.of(context)!;
    final confirmResult = await showConfirmAlertDialog(
      context: context,
      title: l10n.deleteAlbumConfirmationTitle(events.length),
      okLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      showCloseButton: PlatformInfos.isWeb,
    );
    if (confirmResult == ConfirmResult.cancel) return;
    var failureShown = false;
    for (final event in events) {
      final state = await deleteEventInteractor.execute(event).last;
      state.fold((failure) {
        if (failureShown || !context.mounted) return;
        failureShown = true;
        TwakeSnackBar.show(
          context,
          failure is NoPermissionToDeleteEvent
              ? l10n.noDeletePermissionMessage
              : l10n.failedToDeleteMessage,
        );
      }, (success) {});
    }
  }

  void disposeDeleteEventMixin() {
    _streamSubscription?.cancel();
  }
}
