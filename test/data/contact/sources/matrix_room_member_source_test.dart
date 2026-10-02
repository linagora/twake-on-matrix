import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/datasources/matrix_room_member_datasource.dart';
import 'package:twake_chat/data/contact/sources/matrix_room_member_source.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';

class _FakeMatrixRoomMemberDatasource implements MatrixRoomMemberDatasource {
  _FakeMatrixRoomMemberDatasource(this.contacts);

  final List<SourcedContact> contacts;

  @override
  Future<List<SourcedContact>> fetchRoomMembers(String userId) async =>
      contacts;
}

void main() {
  test(
    'delegates the fetch to the datasource for the requested account',
    () async {
      final source = MatrixRoomMemberSource(
        _FakeMatrixRoomMemberDatasource(const [
          SourcedContact(
            matrixId: '@alice:server',
            value: ContactSourceValue(
              kind: ContactSourceKind.matrixRoomMember,
              displayName: 'Alice',
              avatarUrl: 'mxc://server/alice',
            ),
          ),
          SourcedContact(
            matrixId: '@bob:server',
            value: ContactSourceValue(kind: ContactSourceKind.matrixRoomMember),
          ),
        ]),
      );

      final contacts = await source.fetch('@me:server');

      expect(contacts, hasLength(2));
      expect(contacts.first.matrixId, '@alice:server');
      expect(contacts.first.value.kind, ContactSourceKind.matrixRoomMember);
      expect(contacts.first.value.displayName, 'Alice');
      expect(contacts.first.value.avatarUrl, 'mxc://server/alice');
      expect(contacts.last.value.displayName, isNull);
    },
  );

  test('returns nothing when the datasource is empty', () async {
    final source = MatrixRoomMemberSource(
      _FakeMatrixRoomMemberDatasource(const []),
    );

    expect(await source.fetch('@me:server'), isEmpty);
  });
}
