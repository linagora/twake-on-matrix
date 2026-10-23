import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/interceptor/authorization_interceptor.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';

part 'authorization_interceptor.provider.g.dart';

// TODO: [transitional] Bridge: the access token is shared with the legacy
// consumers (ContactsManager, NetworkDI's Dios); kept alive like that GetIt
// singleton.
@Riverpod(keepAlive: true)
AuthorizationInterceptor authorizationInterceptor(Ref ref) =>
    getIt.get<AuthorizationInterceptor>();
