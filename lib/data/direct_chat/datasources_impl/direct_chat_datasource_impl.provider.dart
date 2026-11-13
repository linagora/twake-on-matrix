import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/direct_chat/datasources/direct_chat_datasource.dart';
import 'package:twake_chat/data/direct_chat/datasources_impl/direct_chat_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'direct_chat_datasource_impl.provider.g.dart';

@riverpod
DirectChatDatasource directChatDatasource(Ref ref) =>
    DirectChatDatasourceImpl(ref.watch(activeMatrixClientProvider));
