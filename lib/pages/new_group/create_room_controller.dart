import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/create_room_success.dart';
import 'package:fluffychat/domain/app_state/room/set_room_avatar_failed.dart';
import 'package:fluffychat/domain/app_state/room/set_room_avatar_success.dart';
import 'package:fluffychat/domain/model/room/new_room_request.dart';
import 'package:fluffychat/domain/usecase/create_room_interactor.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

class CreateRoomController {
  final _createRoomInteractor = getIt.get<CreateRoomInteractor>();

  final createRoomStateNotifier = ValueNotifier<Either<Failure, Success>?>(null);

  StreamSubscription? streamSubscription;

  void createRoom(BuildContext context, Client matrixClient, NewRoomRequest newRoomInformations) {
    streamSubscription = _createRoomInteractor.execute(matrixClient, newRoomInformations).listen(
      (event) => _handleCreateRoomOnData(context, event),
      onDone: _handleCreateRoomOnDone,
      onError: _handleCreateRoomOnError
    );
  }

  void _handleCreateRoomOnData(BuildContext context, Either<Failure, Success> event) {
    Logs().d('CreateRoomController::_handleCreateRoomOnData() - event: $event');
    createRoomStateNotifier.value = event;
    event.fold(
      (failure) {
        Logs().e('CreateRoomController::_handleCreateRoomOnData() - failure: $failure');
        if (failure is SetRoomAvatarFailed) {
          _goToRoom(context, failure.roomId);
        }
      },
      (success) {
        Logs().d('CreateRoomController::_handleCreateRoomOnData() - success: $success');
        if (success is CreateRoomSuccess) {
          _goToRoom(context, success.roomId);
        } else if (success is SetRoomAvatarSuccess) {
          _goToRoom(context, success.roomId);
        }
      },
    );
  }

  void _handleCreateRoomOnDone() {
    Logs().d('CreateRoomController::_handleCreateRoomOnDone() - done');
  }

  void _handleCreateRoomOnError(dynamic error, StackTrace? stackTrace) {
    Logs().e('CreateRoomController::_handleCreateRoomOnError() - error: $error | stackTrace: $stackTrace');
  }

  void _goToRoom(BuildContext context, String roomId) {
    VRouter.of(context).toSegments(['rooms', roomId]);
  }

  void dispose() {
    Logs().d('CreateRoomController dispose');
    streamSubscription?.cancel();
  }
}
