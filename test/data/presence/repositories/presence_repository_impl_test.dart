import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/presence/datasources/presence_datasource.dart';
import 'package:twake_chat/data/presence/repositories/presence_repository_impl.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';

const _online = PersonPresence(status: PresenceStatus.online);

class _FakeDatasource implements PresenceDatasource {
  @override
  Stream<PersonPresence?> watchPresence(String userId) =>
      Stream.value(userId == '@alice:s' ? _online : null);
}

void main() {
  test('exposes the datasource stream of the asked user', () async {
    final repository = PresenceRepositoryImpl(_FakeDatasource());

    expect(await repository.watchPresence('@alice:s').toList(), [_online]);
    expect(await repository.watchPresence('@other:s').toList(), [null]);
  });
}
