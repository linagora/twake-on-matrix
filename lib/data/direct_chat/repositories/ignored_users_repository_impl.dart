import 'package:twake_chat/data/direct_chat/datasources/ignored_users_datasource.dart';
import 'package:twake_chat/domain/direct_chat/repositories/ignored_users_repository.dart';

class IgnoredUsersRepositoryImpl implements IgnoredUsersRepository {
  const IgnoredUsersRepositoryImpl(this._datasource);

  final IgnoredUsersDatasource _datasource;

  @override
  Stream<bool> watchIsIgnored(String userId) =>
      _datasource.watchIsIgnored(userId);
}
