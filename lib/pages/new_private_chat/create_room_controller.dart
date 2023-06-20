import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/create_room_success.dart';
import 'package:fluffychat/domain/model/room/new_room_request.dart';
import 'package:fluffychat/domain/usecase/create_room_interactor.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

class CreateRoomController {
  final _createRoomInteractor = getIt.get<CreateRoomInteractor>();

  void createRoom(BuildContext context, Client matrixClient, NewRoomRequest newRoomInformations) {
    _createRoomInteractor.execute(matrixClient, newRoomInformations).listen(
      (event) {
        Logs().d('NewGroupController::createRoom() - event: $event');
        event.fold(
          (failure) => {
            Logs().e('NewGroupController::createRoom() - failure: $failure'),
          },
          (Success success) {
            Logs().d('NewGroupController::createRoom() - success: $success');
            if (success is CreateRoomSuccess) {
              VRouter.of(context).toSegments(['rooms', success.roomId]);
            }
          },
        );
      },
      onDone: () {
        Logs().d('NewGroupController::createRoom() - done');
      },
      onError: (error) {
        Logs().e('NewGroupController::createRoom() - error: $error');
      },
    );
  }
}
