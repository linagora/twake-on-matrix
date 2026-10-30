import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/new_group/new_group_datasource.dart';
import 'package:twake_chat/data/datasource_impl/new_group/new_group_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'new_group_datasource.provider.g.dart';

@riverpod
NewGroupDatasource newGroupDatasource(Ref ref) =>
    NewGroupDatasourceImpl(ref.watch(activeMatrixClientProvider).client);
