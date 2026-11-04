import 'package:twake_chat/data/datasource/new_group/new_group_datasource.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';

class NewGroupRepositoryImpl implements NewGroupRepository {
  const NewGroupRepositoryImpl(this._datasource);

  final NewGroupDatasource _datasource;

  @override
  Future<String> createGroup(CreateNewGroupChatRequest request) =>
      _datasource.createGroup(request);

  @override
  Future<void> inviteUser({required String roomId, required String userId}) =>
      _datasource.inviteUser(roomId: roomId, userId: userId);
}
