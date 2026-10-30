import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/forward/forward_datasource.dart';
import 'package:twake_chat/data/datasource_impl/forward/forward_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'forward_datasource.provider.g.dart';

@riverpod
ForwardDatasource forwardDatasource(Ref ref) =>
    ForwardDatasourceImpl(ref.watch(activeMatrixClientProvider).client);
