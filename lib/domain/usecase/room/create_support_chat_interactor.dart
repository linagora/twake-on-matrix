import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/create_support_chat_state.dart';
import 'package:fluffychat/event/twake_event_types.dart';
import 'package:fluffychat/presentation/mixins/wellknown_mixin.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/power_level_manager.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';

class CreateSupportChatInteractor {
  const CreateSupportChatInteractor();

  Stream<Either<Failure, Success>> execute(Client client) async* {
    yield Right(CreatingSupportChat());

    const type = TwakeEventTypes.supportChatCreatedEventType;
    const accountDataKey = 'createdSupportChat';
    String? roomId;
    String? userId;
    try {
      final discovery = await client.getWellknown();
      final supportChatTwakeId =
          (discovery.additionalProperties[WellKnownMixin.twakeChatKey]
              as Map?)?[WellKnownMixin.supportContact];
      if (supportChatTwakeId is! String || supportChatTwakeId.trim().isEmpty) {
        throw Exception('No support contact found in well-known');
      }

      userId = client.userID;
      if (userId == null) {
        throw Exception('No user id found');
      }

      Map<String, dynamic> supportRoom = {};
      try {
        supportRoom = await client.getAccountData(userId, type);
      } catch (e) {
        Logs().e(
          'CreateSupportChatInteractor: No support room found in account data',
        );
      }
      roomId = supportRoom[accountDataKey] as String?;
      Room? room = roomId != null ? client.getRoomById(roomId) : null;
      if (room != null) {
        yield Right(SupportChatExisted(roomId: roomId!));
        return;
      }

      final avatarMatrixFile = MatrixFile.fromMimeType(
        name: 'logo.png',
        mimeType: 'image/png',
        bytes: (await rootBundle.load(
          ImagePaths.supportAvatarPng,
        )).buffer.asUint8List(),
      );
      final avatarUrl = (await getIt.get<MediaAPI>().uploadFileWeb(
        file: avatarMatrixFile,
      )).contentUri;

      final powerLevelManager = getIt.get<PowerLevelManager>();
      roomId = await client.createGroupChat(
        groupName: 'Support Twake Workplace',
        preset: CreateRoomPreset.trustedPrivateChat,
        enableEncryption: false,
        initialState: [
          if (avatarUrl != null)
            StateEvent(
              type: EventTypes.RoomAvatar,
              content: {'url': avatarUrl},
              stateKey: '',
            ),
        ],
        powerLevelContentOverride: {
          'events': powerLevelManager.getDefaultPowerLevelEventForMember(),
          'invite': powerLevelManager.getAdminPowerLevel(),
          'kick': powerLevelManager.getAdminPowerLevel(),
        },
      );
      room = client.getRoomById(roomId);
      if (room == null) {
        throw Exception('Failed to create support chat');
      }

      await room.invite(supportChatTwakeId);
      await Future.wait([
        room.setPower(
          supportChatTwakeId,
          powerLevelManager.getAdminPowerLevel(),
        ),
        room.setFavourite(true),
        client.setAccountData(userId, type, {accountDataKey: roomId}),
      ]);
      await room.setPower(userId, powerLevelManager.getUserPowerLevel());

      yield Right(SupportChatCreated(roomId: roomId));
    } catch (e) {
      Logs().e('CreateSupportChatInteractor::execute(): Exception', e);
      try {
        await Future.wait([
          if (roomId != null) client.leaveRoom(roomId),
          if (userId != null)
            client.setAccountData(userId, type, {accountDataKey: null}),
        ]);
      } catch (_) {}
      yield Left(CreateSupportChatFailed(exception: e));
    }
  }
}
