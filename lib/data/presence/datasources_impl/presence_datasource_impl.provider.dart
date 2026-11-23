import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/presence/datasources/presence_datasource.dart';
import 'package:twake_chat/data/presence/datasources_impl/presence_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'presence_datasource_impl.provider.g.dart';

@riverpod
PresenceDatasource presenceDatasource(Ref ref) =>
    PresenceDatasourceImpl(ref.watch(activeMatrixClientProvider));
