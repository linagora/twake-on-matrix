import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/direct_chat/create_direct_chat_failed.dart';
import 'package:fluffychat/domain/app_state/direct_chat/create_direct_chat_loading.dart';
import 'package:fluffychat/domain/app_state/direct_chat/create_direct_chat_success.dart';
import 'package:matrix/matrix.dart';

class CreateDirectChatInteractor {
  Stream<Either<Failure, Success>> execute({
    required String contactMxId,
    required Client client,
    List<StateEvent>? initialState,
    bool enableEncryption = true,
    bool waitForSync = true,
    Map<String, dynamic>? powerLevelContentOverride,
    CreateRoomPreset? preset = CreateRoomPreset.trustedPrivateChat,
  }) async* {
    yield const Right(CreateDirectChatLoading());
    try {
      final roomId = await client.startDirectChat(
        contactMxId,
        initialState: initialState,
        enableEncryption: enableEncryption,
        waitForSync: waitForSync,
        powerLevelContentOverride: powerLevelContentOverride,
        preset: preset,
      );
      yield Right(CreateDirectChatSuccess(roomId: roomId));
    } catch (e) {
      yield Left(CreateDirectChatFailed(exception: e));
    }
  }
}
