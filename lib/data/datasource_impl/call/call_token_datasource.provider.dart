import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/call/call_token_datasource.dart';
import 'package:twake_chat/data/datasource_impl/call/sfu_call_token_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'call_token_datasource.provider.g.dart';

@Riverpod(keepAlive: true)
CallTokenDatasource callTokenDatasource(Ref ref) => SfuCallTokenDatasourceImpl(
  ref.watch(activeMatrixClientProvider)?.httpClient ?? http.Client(),
);
