import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/create_room_failed.dart';
import 'package:fluffychat/domain/app_state/room/create_room_loading.dart';
import 'package:fluffychat/domain/app_state/room/create_room_success.dart';
import 'package:fluffychat/domain/exception/room/can_not_create_room.dart';
import 'package:fluffychat/domain/model/room/new_room_request.dart';
import 'package:fluffychat/domain/usecase/set_room_avatar_interactor.dart';
import 'package:matrix/matrix.dart';

class CreateRoomInteractor {
  final setRoomAvatarInteractor = getIt.get<SetRoomAvatarInteractor>();

  Stream<Either<Failure, Success>> execute(Client matrixClient, NewRoomRequest newRoomInformations) async* {
    try {
      yield Right(CreateRoomLoading());

      final roomId = await matrixClient.createGroupChat(
        groupName: newRoomInformations.groupName,
        invite: newRoomInformations.invite,
        enableEncryption: newRoomInformations.enableEncryption,
        preset: newRoomInformations.createRoomPreset,
      );

      if (roomId.isNotEmpty) {
        final withAvatarUpload = newRoomInformations.avatar != null;

        if (withAvatarUpload) {
          yield* setRoomAvatarInteractor.execute(matrixClient, roomId, newRoomInformations.avatar);
        } else {
          yield Right(CreateRoomSuccess(roomId: roomId));
        }
      } else {
        yield Left(CreateRoomFailed(exception: CannotCreateRoom()));
      }
    } catch (exception) {
      yield Left(CreateRoomFailed(exception: exception));
    }
  }
}
