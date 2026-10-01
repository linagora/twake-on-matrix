import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/contact/datasources/matrix_room_member_datasource.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';

class MatrixRoomMemberDatasourceImpl implements MatrixRoomMemberDatasource {
  const MatrixRoomMemberDatasourceImpl(this._client, {this.maxMembers = 5000});

  final Client? _client;

  /// Upper bound on collected members: huge public rooms would otherwise
  /// flood the contact store with one-off contacts.
  final int maxMembers;

  @override
  Future<List<SourcedContact>> fetchRoomMembers(String userId) async {
    final client = _client;
    if (client == null || !client.isLogged()) return const [];
    if (client.userID != userId) {
      throw StateError(
        'MatrixRoomMemberDatasourceImpl is bound to ${client.userID}, '
        'cannot fetch members for $userId',
      );
    }

    // Seeded with our own id: the current user is never a contact of itself.
    final seenMatrixIds = <String>{userId};
    final members = <SourcedContact>[];

    for (final room in client.rooms) {
      for (final user in room.getParticipants()) {
        if (members.length >= maxMembers) return members;
        final matrixId = user.id;
        if (matrixId.isEmpty || !seenMatrixIds.add(matrixId)) continue;
        members.add(
          SourcedContact(
            matrixId: matrixId,
            value: ContactSourceValue(
              kind: ContactSourceKind.matrixRoomMember,
              displayName: user.calcDisplayname(),
              avatarUrl: user.avatarUrl?.toString(),
            ),
          ),
        );
      }
    }

    return members;
  }
}
