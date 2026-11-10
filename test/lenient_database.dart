import 'package:matrix/matrix.dart';

import 'fake_client.dart';

/// The shared [MockDatabase] returns null for the store calls that the sync
/// code awaits. This one answers every call that is not stubbed with a
/// completed future, so a fake sync can run against a real [Client].
class LenientDatabase extends MockDatabase {
  @override
  dynamic noSuchMethod(
    Invocation invocation, {
    Object? returnValue,
    Object? returnValueForMissingStub,
  }) => Future<void>.value();
}

/// A joined [Room] on a client that uses [LenientDatabase].
Future<Room> getLenientRoom(String id) async {
  final client = await getClient(database: LenientDatabase());
  return Room(client: client, id: id, membership: Membership.join);
}
