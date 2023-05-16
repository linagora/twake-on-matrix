import 'package:fluffychat/data/datasource/tom_configurations_datasource.dart';
import 'package:fluffychat/data/datasource_impl/tom_configurations_datasource_impl.dart';
import 'package:fluffychat/data/repository/tom_configurations_repository_impl.dart';
import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/domain/repository/tom_configurations_repository.dart';
import 'package:get_it/get_it.dart';

class ToMConfigurationDI extends BaseDI {
  @override
  String get scopeName => 'ToM Configuration';

  @override
  void setUp(GetIt get) {
    _bindDataSource(get);
    _bindRepository(get);
  }

  void _bindDataSource(GetIt get) {
    get.registerFactory<ToMConfigurationsDatasource>(() => HiveToMConfigurationDatasource());
  }

  void _bindRepository(GetIt get) {
    get.registerFactory<ToMConfigurationsRepository>(() => ToMConfigurationsRepositoryImpl());
  }
}