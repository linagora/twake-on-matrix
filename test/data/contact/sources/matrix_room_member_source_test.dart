import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/datasources/matrix_room_member_datasource.dart';
import 'package:twake_chat/data/contact/sources/matrix_room_member_source.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';

class _FakeMatrixRoomMemberDatasource implements MatrixRoomMemberDatasource {
  _FakeMatrixRoomMemberDatasource(this.members);

  final List<MatrixRoomMemberProfile> members;

  @override
  Future<List<MatrixRoomMemberProfile>> fetchRoomMembers() async => members;
}

void main() {
  test('maps room members to matrixRoomMember sourced contacts', () async {
    final source = MatrixRoomMemberSource(
      _FakeMatrixRoomMemberDatasource(const [
        MatrixRoomMemberProfile(
          matrixId: '@alice:server',
          displayName: 'Alice',
          avatarUrl: 'mxc://server/alice',
        ),
        MatrixRoomMemberProfile(matrixId: '@bob:server'),
      ]),
    );

    final contacts = await source.fetch();

    expect(contacts, hasLength(2));
    expect(contacts.first.matrixId, '@alice:server');
    expect(contacts.first.value.kind, ContactSourceKind.matrixRoomMember);
    expect(contacts.first.value.displayName, 'Alice');
    expect(contacts.first.value.avatarUrl, 'mxc://server/alice');
    expect(contacts.last.value.displayName, isNull);
  });

  test('returns nothing when the datasource is empty', () async {
    final source = MatrixRoomMemberSource(
      _FakeMatrixRoomMemberDatasource(const []),
    );

    expect(await source.fetch(), isEmpty);
  });
}
