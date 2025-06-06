import 'dart:async';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/delete_event_state.dart';
import 'package:fluffychat/domain/usecase/room/delete_event_interactor.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

mixin DeleteEventMixin {
  final deleteEventInteractor = getIt.get<DeleteEventInteractor>();
  StreamSubscription? _streamSubscription;

  Future<void> deleteEventAction(BuildContext context, Event event) async {
    _streamSubscription = deleteEventInteractor.execute(event).listen((state) {
      state.fold(
        (failure) {
          if (failure is NoPermissionToDeleteEvent) {
            TwakeSnackBar.show(
              context,
              L10n.of(context)!.noDeletePermissionMessage,
            );
            return;
          }
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.failedToDeleteMessage,
          );
        },
        (success) {},
      );
    });
  }

  void disposeDeleteEventMixin() {
    _streamSubscription?.cancel();
  }
}
