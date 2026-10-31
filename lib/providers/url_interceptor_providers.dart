import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';

part 'url_interceptor_providers.g.dart';

/// The interceptor registered under [name] (`NetworkDI.*InterceptorName`).
@Riverpod(keepAlive: true)
DynamicUrlInterceptors dynamicUrlInterceptors(Ref ref, String name) =>
    getIt.get<DynamicUrlInterceptors>(instanceName: name);
