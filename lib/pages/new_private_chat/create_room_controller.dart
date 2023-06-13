import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/new_room_request.dart';
import 'package:fluffychat/domain/usecase/create_room_interactor.dart';
import 'package:matrix/matrix.dart';

class CreateRoomController {
  final _createRoomInteractor = getIt.get<CreateRoomInteractor>();
  final streamController = StreamController<Either<Failure, Success>>();

  void createRoom(Client matrixClient, NewRoomRequest newRoomInformations) {
    _createRoomInteractor
      .execute(matrixClient, newRoomInformations)
      .listen((event) {
        streamController.add(event);
      });
  }

  void dispose() {
    streamController.close();
  }
}