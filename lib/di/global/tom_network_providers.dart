import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/di/global/get_it_provider.dart';
import 'package:twake_chat/di/global/network_di.dart';

part 'tom_network_providers.g.dart';

@Riverpod(keepAlive: true)
DioClient tomDioClient(Ref ref) => ref
    .watch(getItProvider)
    .get<DioClient>(instanceName: NetworkDI.tomDioClientName);

@Riverpod(keepAlive: true)
DynamicUrlInterceptors tomServerUrlInterceptor(Ref ref) => ref
    .watch(getItProvider)
    .get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.tomServerUrlInterceptorName,
    );
