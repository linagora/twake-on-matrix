import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/contact/datasources_impl/matrix_profile_datasource_impl.dart';
import 'package:twake_chat/data/profile/datasources_impl/account_profiles_datasource_impl.provider.dart';
import 'package:twake_chat/data/profile/repositories/profile_repository_impl.dart';
import 'package:twake_chat/domain/profile/repositories/profile_repository.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'profile_repository_impl.provider.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) => ProfileRepositoryImpl(
  MatrixProfileDatasourceImpl(ref.watch(activeMatrixClientProvider)),
  ref.watch(accountProfilesDatasourceProvider),
);
