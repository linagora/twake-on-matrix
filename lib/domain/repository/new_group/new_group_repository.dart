import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';

abstract class NewGroupRepository {
  Future<String> createGroup(CreateNewGroupChatRequest request);

  /// Throws an `InviteUserException`.
  Future<void> inviteUser({required String roomId, required String userId});
}
