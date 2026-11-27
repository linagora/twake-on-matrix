import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/presence/datasources/presence_datasource.dart';
import 'package:twake_chat/data/presence/repositories/presence_repository_impl.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';

const _online = PersonPresence(status: PresenceStatus.online);

class _FakeDatasource implements PresenceDatasource {
  final serverReads = <bool>[];

  @override
  Stream<PersonPresence?> watchPresence(
    String userId, {
    required bool readFromServer,
  }) {
    serverReads.add(readFromServer);
    return Stream.value(userId == '@alice:s' ? _online : null);
  }
}

void main() {
  test('exposes the datasource stream of the asked user', () async {
    final repository = PresenceRepositoryImpl(_FakeDatasource());

    expect(
      await repository.watchPresence('@alice:s', readFromServer: true).toList(),
      [_online],
    );
    expect(
      await repository.watchPresence('@other:s', readFromServer: true).toList(),
      [null],
    );
  });

  test('passes on whether to read the server', () async {
    final datasource = _FakeDatasource();
    final repository = PresenceRepositoryImpl(datasource);

    await repository.watchPresence('@alice:s', readFromServer: false).toList();
    await repository.watchPresence('@alice:s', readFromServer: true).toList();

    expect(datasource.serverReads, [false, true]);
  });
}
