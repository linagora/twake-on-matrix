import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/dio_client.provider.dart';
import 'package:twake_chat/data/network/interceptor/matrix_dio_cache_interceptor.provider.dart';
import 'package:twake_chat/data/network/user_info/user_info_api.dart';

part 'user_info_api.provider.g.dart';

@Riverpod(keepAlive: true)
UserInfoApi userInfoApi(Ref ref) => UserInfoApi(
  ref.watch(legacyTomDioClientProvider),
  ref.watch(memCacheDioInterceptorProvider),
);
