import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/config/app_grid_config/app_config_loader.dart';

part 'app_config_loader.provider.g.dart';

@riverpod
AppConfigLoader appConfigLoader(Ref ref) => AppConfigLoader();
