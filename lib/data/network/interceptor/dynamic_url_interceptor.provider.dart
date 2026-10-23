import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/di/global/network_di.dart';

part 'dynamic_url_interceptor.provider.g.dart';

// TODO: [transitional] Bridge: the ToM base url is shared with the legacy
// consumers (NetworkDI's ToM Dio, GetTomContactsInteractor); kept alive like
// that GetIt singleton.
@Riverpod(keepAlive: true)
DynamicUrlInterceptors tomServerUrlInterceptor(Ref ref) =>
    getIt.get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.tomServerUrlInterceptorName,
    );
