import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/contact/datasources_impl/matrix_room_member_datasource_impl.dart';

import 'matrix_room_member_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>(), MockSpec<User>()])
void main() {
  const userId = '@me:server';
  late MockClient client;
  late MockRoom room;
  late MatrixRoomMemberDatasourceImpl datasource;

  MockUser member(String matrixId, {String? displayName}) {
    final user = MockUser();
    when(user.id).thenReturn(matrixId);
    when(user.calcDisplayname()).thenReturn(displayName ?? matrixId);
    return user;
  }

  setUp(() {
    client = MockClient();
    room = MockRoom();
    when(client.isLogged()).thenReturn(true);
    when(client.userID).thenReturn(userId);
    when(client.rooms).thenReturn([room]);
    datasource = MatrixRoomMemberDatasourceImpl(client);
  });

  test('returns the deduplicated members of the joined rooms', () async {
    final members = [
      member('@alice:server', displayName: 'Alice'),
      member('@alice:server'),
      member('@bob:server'),
    ];
    when(room.getParticipants()).thenReturn(members);

    final contacts = await datasource.fetchRoomMembers(userId);

    expect(contacts.map((contact) => contact.matrixId), [
      '@alice:server',
      '@bob:server',
    ]);
    expect(contacts.first.value.displayName, 'Alice');
  });

  test('excludes the current user from the members', () async {
    final members = [member(userId), member('@alice:server')];
    when(room.getParticipants()).thenReturn(members);

    final contacts = await datasource.fetchRoomMembers(userId);

    expect(contacts.map((contact) => contact.matrixId), ['@alice:server']);
  });

  test('caps the collected members at maxMembers', () async {
    datasource = MatrixRoomMemberDatasourceImpl(client, maxMembers: 2);
    final members = [
      member('@a:server'),
      member('@b:server'),
      member('@c:server'),
    ];
    when(room.getParticipants()).thenReturn(members);

    final contacts = await datasource.fetchRoomMembers(userId);

    expect(contacts, hasLength(2));
  });

  test('throws when asked to fetch the members of another account', () {
    expect(
      () => datasource.fetchRoomMembers('@other:server'),
      throwsStateError,
    );
  });

  test('returns nothing when logged out', () async {
    when(client.isLogged()).thenReturn(false);

    expect(await datasource.fetchRoomMembers(userId), isEmpty);
  });

  test('returns nothing when no client is bound', () async {
    datasource = const MatrixRoomMemberDatasourceImpl(null);

    expect(await datasource.fetchRoomMembers(userId), isEmpty);
  });
}
