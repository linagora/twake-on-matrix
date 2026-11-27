import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/profile/datasources/own_profile_datasource.dart';
import 'package:twake_chat/data/profile/datasources_impl/own_profile_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'own_profile_datasource_impl.provider.g.dart';

@riverpod
OwnProfileDatasource ownProfileDatasource(Ref ref) =>
    OwnProfileDatasourceImpl(ref.watch(activeMatrixClientProvider));
