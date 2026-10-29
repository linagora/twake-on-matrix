import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/app_grid/repositories/app_grid_repository.provider.dart';
import 'package:twake_chat/domain/app_grid/usecases/get_app_grid_configuration.dart';

part 'get_app_grid_configuration.provider.g.dart';

@riverpod
GetAppGridConfiguration getAppGridConfiguration(Ref ref) =>
    GetAppGridConfiguration(ref.watch(appGridRepositoryProvider));
