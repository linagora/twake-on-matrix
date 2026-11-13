import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/direct_chat/datasources/ignored_users_datasource.dart';
import 'package:twake_chat/data/direct_chat/datasources_impl/ignored_users_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'ignored_users_datasource_impl.provider.g.dart';

@riverpod
IgnoredUsersDatasource ignoredUsersDatasource(Ref ref) =>
    IgnoredUsersDatasourceImpl(ref.watch(activeMatrixClientProvider));
