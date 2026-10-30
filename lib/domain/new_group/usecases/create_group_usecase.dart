import 'package:twake_chat/domain/exception/room/can_not_create_new_group_chat_exception.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';

class CreateGroupUseCase {
  const CreateGroupUseCase(this._repository);

  final NewGroupRepository _repository;

  /// Returns the room id. Throws a [FederationDeniedWithMatrixOrgException],
  /// a [CannotCreateNewGroupChatWithLimitedPermissionsException] or a
  /// [CannotCreateNewGroupChatException]; other errors are rethrown.
  Future<String> execute(CreateNewGroupChatRequest request) async {
    final String roomId;
    try {
      roomId = await _repository.createGroup(request);
    } catch (exception) {
      final message = exception.toString();
      if (message.contains('M_FORBIDDEN: Federation denied')) {
        throw FederationDeniedWithMatrixOrgException();
      }
      if (message.contains('M_UNKNOWN: Cannot invite so many users at once')) {
        throw CannotCreateNewGroupChatWithLimitedPermissionsException();
      }
      rethrow;
    }
    if (roomId.isEmpty) throw CannotCreateNewGroupChatException();
    return roomId;
  }
}
