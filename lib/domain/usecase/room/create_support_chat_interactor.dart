import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/create_support_chat_state.dart';
import 'package:fluffychat/event/twake_event_types.dart';
import 'package:fluffychat/presentation/mixins/wellknown_mixin.dart';
import 'package:matrix/matrix.dart';

class CreateSupportChatInteractor {
  const CreateSupportChatInteractor();

  Stream<Either<Failure, Success>> execute(
    Client client, {
    DiscoveryInformation? cachedDiscovery,
  }) async* {
    yield Right(CreatingSupportChat());

    const type = TwakeEventTypes.supportChatCreatedEventType;
    const accountDataKey = 'createdSupportChat';
    String? roomId;
    String? userId;
    try {
      if (cachedDiscovery == null) {
        throw Exception('No cached discovery information available');
      }
      final discovery = cachedDiscovery;
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

      roomId = await client.startDirectChat(
        supportChatTwakeId,
        preset: CreateRoomPreset.privateChat,
        enableEncryption: false,
      );
      room = client.getRoomById(roomId);
      if (room == null) {
        throw Exception('Failed to create support chat');
      }

      await Future.wait([
        room.setFavourite(true),
        client.setAccountData(userId, type, {accountDataKey: roomId}),
      ]);

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
