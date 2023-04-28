import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/pages/contacts/data/datasource/contact_data_source.dart';
import 'package:fluffychat/pages/contacts/data/datasource/device_contact_data_source.dart';
import 'package:fluffychat/pages/contacts/data/datasource/tomclient_data_source.dart';
import 'package:fluffychat/pages/contacts/data/repository/local_contact_repository_impl.dart';
import 'package:fluffychat/pages/contacts/data/repository/network_contact_repository_impl.dart';
import 'package:fluffychat/pages/contacts/domain/repository/local_contact_repository.dart';
import 'package:fluffychat/pages/contacts/domain/repository/network_contact_repository.dart';
import 'package:fluffychat/pages/contacts/domain/usecases/get_local_contacts_interactor.dart';
import 'package:fluffychat/pages/contacts/domain/usecases/get_network_contacts_interactor.dart';
import 'package:get_it/get_it.dart';

class ContactDI extends BaseDI {

  @override
  String get scopeName => 'Contacts';

  @override
  void setUp(GetIt get) {
    get.registerFactory<DeviceContactDataSource>(() => DeviceContactDataSource());
    get.registerFactory<TomClientDataSource>(() => TomClientDataSource());
    
    get.registerFactory<LocalContactRepository>(
      () => LocalContactRepositoryImpl(datasources: {
        LocalDataSourceType.device: get.get<DeviceContactDataSource>()
      }));
    get.registerFactory<NetworkContactRepository>(
      () => NetworkContactRepositoryImpl(datasources: {
        NetworkDataSourceType.tomclient: get.get<TomClientDataSource>()
      }));
    
    get.registerFactory(() => GetLocalContactsInteractor(
      localContactRepository: get.get<LocalContactRepository>()));
    get.registerFactory(() => GetNetworkContactsInteractor(
      networkContactRepository: get.get<NetworkContactRepository>()));
  }

}