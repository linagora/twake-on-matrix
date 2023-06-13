import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/create_room_failed.dart';
import 'package:fluffychat/domain/app_state/room/create_room_end_action_success.dart';
import 'package:fluffychat/domain/app_state/room/create_room_success.dart';
import 'package:fluffychat/domain/model/room/new_room_request.dart';
import 'package:fluffychat/domain/usecase/set_room_avatar_interactor.dart';
import 'package:matrix/matrix.dart';

class CreateRoomInteractor {
  final setRoomAvatarInteractor = getIt.get<SetRoomAvatarInteractor>();

  Stream<Either<Failure, Success>> execute(Client matrixClient, NewRoomRequest newRoomInformations) async* {
    try {
      final roomId = await matrixClient.createGroupChat(
        groupName: newRoomInformations.groupName,
        invite: newRoomInformations.invite,
        enableEncryption: newRoomInformations.enableEncryption,
        preset: newRoomInformations.createRoomPreset,
      );

      final withAvatarUpload = newRoomInformations.avatar != null;

      if (roomId.isNotEmpty) {
        yield Right(CreateRoomSuccess(roomId: roomId));

        if (withAvatarUpload) {
          final Stream<Either<Failure, Success>> setRoomAvatarStream = setRoomAvatarInteractor.execute(matrixClient, roomId, newRoomInformations.avatar);
          yield* setRoomAvatarStream;
        }
        yield Right(CreateRoomEndActionSuccess(roomId: roomId));
      }
    } catch (exception) {
      yield Left(CreateRoomFailed(exception: exception));
    }
  }
}
