import 'package:dio/dio.dart';
import 'package:fluffychat/data/datasource_impl/contact/tom_contacts_datasource_impl.dart';
import 'package:fluffychat/data/network/contact/tom_contact_api.dart';
import 'package:fluffychat/data/repository/contact/tom_contact_repository.dart';
import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/usecase/fetch_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/lookup_contacts_interactor.dart';
import 'package:fluffychat/network/interceptor/authorization_interceptor.dart';
import 'package:get_it/get_it.dart';

class ContactDI extends BaseDI {

  @override
  String get scopeName => 'Contacts';

  @override
  void setUp(GetIt get) {
    final dio = Dio(get.get<BaseOptions>());
    dio.interceptors.add(get.get<AuthorizationInterceptor>());

    get.registerFactory<TomContactAPI>(() => TomContactAPI(client: get.get(instanceName: NetworkDI.identityDioClientName)));

    get.registerFactory<TomContactsDatasourceImpl>(() => TomContactsDatasourceImpl(tomContactAPI: get.get<TomContactAPI>()));

    get.registerFactory<TomContactRepositoryImpl>(
      () => TomContactRepositoryImpl(datasource: get.get<TomContactsDatasourceImpl>()));
    
    get.registerFactory(() => LookupContactsInteractor(
      contactRepository: get.get<TomContactRepositoryImpl>()));
    get.registerFactory(() => FetchContactsInteractor(
      contactRepository: get.get<TomContactRepositoryImpl>()));
  }

}