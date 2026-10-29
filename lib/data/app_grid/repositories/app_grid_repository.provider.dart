import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/config/app_grid_config/app_config_loader.provider.dart';
import 'package:twake_chat/data/app_grid/repositories/app_grid_repository_impl.dart';
import 'package:twake_chat/domain/app_grid/repositories/app_grid_repository.dart';

part 'app_grid_repository.provider.g.dart';

@riverpod
AppGridRepository appGridRepository(Ref ref) =>
    AppGridRepositoryImpl(ref.watch(appConfigLoaderProvider));
