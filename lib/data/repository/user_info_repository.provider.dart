import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/user_info/user_info_datasource.provider.dart';
import 'package:twake_chat/data/repository/user_info_repository_impl.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';

part 'user_info_repository.provider.g.dart';

// Kept alive for tomUserInfoEnricher, a keepAlive provider.
@Riverpod(keepAlive: true)
UserInfoRepository userInfoRepository(Ref ref) =>
    UserInfoRepositoryImpl(ref.watch(userInfoDatasourceProvider));
