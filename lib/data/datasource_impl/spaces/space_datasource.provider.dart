import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/spaces/space_datasource.dart';
import 'package:twake_chat/data/datasource_impl/spaces/space_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'space_datasource.provider.g.dart';

@riverpod
SpaceDatasource spaceDatasource(Ref ref) =>
    SpaceDatasourceImpl(ref.watch(activeMatrixClientProvider));
