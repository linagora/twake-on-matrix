import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/call/call_media_datasource.provider.dart';
import 'package:twake_chat/data/datasource_impl/call/call_token_datasource.provider.dart';
import 'package:twake_chat/data/datasource_impl/call/matrix_rtc_datasource.provider.dart';
import 'package:twake_chat/data/repository/call/call_repository_impl.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

part 'call_repository.provider.g.dart';

@Riverpod(keepAlive: true)
CallRepository callRepository(Ref ref) => CallRepositoryImpl(
  rtcDatasource: ref.watch(matrixRtcDatasourceProvider),
  tokenDatasource: ref.watch(callTokenDatasourceProvider),
  mediaDatasource: ref.watch(callMediaDatasourceProvider),
);
