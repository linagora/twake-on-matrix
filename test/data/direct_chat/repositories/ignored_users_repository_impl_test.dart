import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/direct_chat/datasources/ignored_users_datasource.dart';
import 'package:twake_chat/data/direct_chat/repositories/ignored_users_repository_impl.dart';

class _FakeDatasource implements IgnoredUsersDatasource {
  @override
  Stream<bool> watchIsIgnored(String userId) =>
      Stream.value(userId == '@blocked:s');
}

void main() {
  test('exposes the datasource stream of the asked user', () async {
    final repository = IgnoredUsersRepositoryImpl(_FakeDatasource());

    expect(await repository.watchIsIgnored('@blocked:s').toList(), [true]);
    expect(await repository.watchIsIgnored('@other:s').toList(), [false]);
  });
}
