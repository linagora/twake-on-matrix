import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/direct_chat/datasources_impl/ignored_users_datasource_impl.provider.dart';
import 'package:twake_chat/data/direct_chat/repositories/ignored_users_repository_impl.dart';
import 'package:twake_chat/domain/direct_chat/repositories/ignored_users_repository.dart';

part 'ignored_users_repository_impl.provider.g.dart';

@riverpod
IgnoredUsersRepository ignoredUsersRepository(Ref ref) =>
    IgnoredUsersRepositoryImpl(ref.watch(ignoredUsersDatasourceProvider));
