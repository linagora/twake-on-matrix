import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';
import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/new_space.dart';

/// The same name for everyone, as the React client.
const String generalRoomName = 'General';

class CreateSpaceUseCase {
  const CreateSpaceUseCase(this._spaces, this._groups);

  final SpaceRepository _spaces;
  final NewGroupRepository _groups;

  /// Creates [space] with its General channel, for a space is no conversation.
  /// A failure of General leaves the space, whose home offers a new group.
  ///
  /// Throws a [SpaceException].
  Future<String> execute(NewSpace space) async {
    final roomId = await _spaces.createSpace(space);
    try {
      await _groups.createGroup(
        CreateNewGroupChatRequest(
          groupName: generalRoomName,
          enableEncryption: false,
          parentSpaceId: roomId,
          isSuggested: true,
        ),
      );
    } on Exception {
      // The datasource logged why; the space stands without General.
    }
    return roomId;
  }
}
