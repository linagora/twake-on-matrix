import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/contact/datasources/matrix_room_member_datasource.dart';

class MatrixRoomMemberDatasourceImpl implements MatrixRoomMemberDatasource {
  const MatrixRoomMemberDatasourceImpl(this._client);

  final Client? _client;

  @override
  Future<List<MatrixRoomMemberProfile>> fetchRoomMembers() async {
    final client = _client;
    if (client == null || !client.isLogged()) return const [];

    final seenMatrixIds = <String>{};
    final members = <MatrixRoomMemberProfile>[];

    for (final room in client.rooms) {
      for (final user in room.getParticipants()) {
        final matrixId = user.id;
        if (matrixId.isEmpty || !seenMatrixIds.add(matrixId)) continue;
        members.add(
          MatrixRoomMemberProfile(
            matrixId: matrixId,
            displayName: user.calcDisplayname(),
            avatarUrl: user.avatarUrl?.toString(),
          ),
        );
      }
    }

    return members;
  }
}
