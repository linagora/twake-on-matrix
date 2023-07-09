import 'package:fluffychat/data/datasource/tom_contacts_datasource.dart';
import 'package:fluffychat/data/datasource_impl/contact/tom_contacts_datasource_impl.dart';
import 'package:fluffychat/data/network/contact/tom_contact_api.dart';
import 'package:fluffychat/data/repository/contact/tom_contact_repository_impl.dart';
import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';
import 'package:fluffychat/domain/usecase/fetch_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/load_more_internal_contacts.dart';
import 'package:fluffychat/domain/usecase/lookup_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/search/search_interactor.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';

class SearchDI extends BaseDI {

  @override
  String get scopeName => 'Search';

  @override
  void setUp(GetIt get) {
    Logs().d('SearchDI::setUp()');

    get.registerFactory<TomContactAPI>(() => TomContactAPI());

    get.registerFactory<TomContactsDatasource>(() => TomContactsDatasourceImpl());

    get.registerFactory<ContactRepository>(() => TomContactRepositoryImpl());

    get.registerFactory<LookupContactsInteractor>(() => LookupContactsInteractor());

    get.registerFactory<FetchContactsInteractor>(() => FetchContactsInteractor());

    get.registerFactory<LoadMoreInternalContacts>(() => LoadMoreInternalContacts());

    get.registerFactory<SearchContactsAndRecentChatInteractor>(() => SearchContactsAndRecentChatInteractor());

    Logs().d('SearchDI::setUp() - done');
  }
}