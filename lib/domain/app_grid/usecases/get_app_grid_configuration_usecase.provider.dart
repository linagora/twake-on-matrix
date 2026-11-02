import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/config/app_grid_config/app_config_loader.provider.dart';
import 'package:twake_chat/domain/app_grid/usecases/get_app_grid_configuration_usecase.dart';

part 'get_app_grid_configuration_usecase.provider.g.dart';

@riverpod
GetAppGridConfigurationUseCase getAppGridConfigurationUseCase(Ref ref) =>
    GetAppGridConfigurationUseCase(ref.watch(appConfigLoaderProvider));
