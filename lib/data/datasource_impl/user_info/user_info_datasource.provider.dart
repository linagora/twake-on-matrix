import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/user_info/user_info_datasource.dart';
import 'package:twake_chat/data/datasource_impl/user_info/user_info_datasource_impl.dart';
import 'package:twake_chat/data/network/user_info/user_info_api.provider.dart';

part 'user_info_datasource.provider.g.dart';

@Riverpod(keepAlive: true)
UserInfoDatasource userInfoDatasource(Ref ref) =>
    UserInfoDatasourceImpl(ref.watch(userInfoApiProvider));
