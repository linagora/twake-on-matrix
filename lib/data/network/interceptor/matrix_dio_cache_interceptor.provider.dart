import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/interceptor/matrix_dio_cache_interceptor.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/di/global/network_di.dart';

part 'matrix_dio_cache_interceptor.provider.g.dart';

// TODO: [transitional] Bridge: the memory cache is shared with the legacy
// consumers (NetworkDI's Dios, InvitationAPI, the GetIt UserInfoRepository);
// kept alive like that GetIt singleton.
@Riverpod(keepAlive: true)
MatrixDioCacheInterceptor memCacheDioInterceptor(Ref ref) =>
    getIt.get<MatrixDioCacheInterceptor>(
      instanceName: NetworkDI.memCacheDioInterceptorName,
    );
