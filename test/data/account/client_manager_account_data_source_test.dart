import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/datasources_impl/client_manager_account_data_source.dart';

class _FakeDatabase extends Fake implements DatabaseApi {
  _FakeDatabase(this.calls);

  final List<String> calls;
  bool failDelete = false;

  @override
  Future<void> delete() async {
    calls.add('delete');
    if (failDelete) throw StateError('disk');
  }
}

class _DisposableClient extends Fake implements Client {
  _DisposableClient(this.calls) : database = _FakeDatabase(calls);

  final List<String> calls;
  bool failDispose = false;

  @override
  final _FakeDatabase database;

  @override
  String get clientName => 'c1';

  @override
  Future<void> dispose({bool closeDatabase = true}) async {
    calls.add('dispose');
    if (failDispose) throw StateError('dispose');
  }
}

void main() {
  late List<String> calls;
  late _DisposableClient client;
  late ClientManagerAccountDataSource source;

  setUp(() {
    calls = [];
    client = _DisposableClient(calls);
    source = ClientManagerAccountDataSource();
  });

  test('disposes the client, then deletes its database', () async {
    await source.disposeAndDeleteStorage(client);

    expect(calls, ['dispose', 'delete']);
  });

  test('a disposal that fails is reported, nothing is deleted', () async {
    client.failDispose = true;

    await expectLater(source.disposeAndDeleteStorage(client), throwsStateError);

    expect(calls, ['dispose']);
  });

  test('a retry after a failed disposal disposes the client again', () async {
    client.failDispose = true;
    await expectLater(source.disposeAndDeleteStorage(client), throwsStateError);
    client.failDispose = false;

    await source.disposeAndDeleteStorage(client);

    expect(calls, ['dispose', 'dispose', 'delete']);
  });

  test('a retry after a failed delete does not dispose twice', () async {
    client.database.failDelete = true;
    await expectLater(source.disposeAndDeleteStorage(client), throwsStateError);
    client.database.failDelete = false;

    await source.disposeAndDeleteStorage(client);

    expect(calls, ['dispose', 'delete', 'delete']);
  });

  test('a repeat after a success disposes and deletes nothing again', () async {
    await source.disposeAndDeleteStorage(client);

    await source.disposeAndDeleteStorage(client);

    expect(calls, ['dispose', 'delete']);
  });

  test('a repeat after a failed delete resumes, then stays done', () async {
    client.database.failDelete = true;
    await expectLater(source.disposeAndDeleteStorage(client), throwsStateError);
    client.database.failDelete = false;
    await source.disposeAndDeleteStorage(client);

    await source.disposeAndDeleteStorage(client);

    expect(calls, ['dispose', 'delete', 'delete']);
  });

  test('a client that is not done is not held back by another', () async {
    final other = _DisposableClient(calls);
    await source.disposeAndDeleteStorage(client);

    await source.disposeAndDeleteStorage(other);

    expect(calls, ['dispose', 'delete', 'dispose', 'delete']);
  });

  test('a new client with the same name is disposed and deleted', () async {
    await source.disposeAndDeleteStorage(client);
    final recreated = _DisposableClient(calls);

    await source.disposeAndDeleteStorage(recreated);

    expect(calls, ['dispose', 'delete', 'dispose', 'delete']);
  });
}
