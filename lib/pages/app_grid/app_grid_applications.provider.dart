import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/app_grid/usecases/get_app_grid_configuration.provider.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';

part 'app_grid_applications.provider.g.dart';

@riverpod
Future<LinagoraApplications> appGridApplications(Ref ref) => ref
    .watch(getAppGridConfigurationProvider)
    .execute(path: AppConfig.appGridConfigurationPath);
