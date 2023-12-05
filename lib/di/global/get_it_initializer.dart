import 'dart:collection';

import 'package:fluffychat/data/datasource/localizations/localizations_datasource.dart';
import 'package:fluffychat/data/datasource/lookup_datasource.dart';
import 'package:fluffychat/data/datasource/media/media_data_source.dart';
import 'package:fluffychat/data/datasource/phonebook_datasouce.dart';
import 'package:fluffychat/data/datasource/recovery_words_data_source.dart';
import 'package:fluffychat/data/datasource/server_search_datasource.dart';
import 'package:fluffychat/data/datasource/tom_configurations_datasource.dart';
import 'package:fluffychat/data/datasource/tom_contacts_datasource.dart';
import 'package:fluffychat/data/datasource_impl/contact/lookup_datasource_impl.dart';
import 'package:fluffychat/data/datasource_impl/contact/phonebook_contact_datasource_impl.dart';
import 'package:fluffychat/data/datasource_impl/contact/tom_contacts_datasource_impl.dart';
import 'package:fluffychat/data/datasource_impl/localizations/localizations_datasource_impl.dart';
import 'package:fluffychat/data/datasource_impl/media/media_data_source_impl.dart';
import 'package:fluffychat/data/datasource_impl/recovery_words_data_source_impl.dart';
import 'package:fluffychat/data/datasource_impl/server_search_datasource_impl.dart';
import 'package:fluffychat/data/datasource_impl/tom_configurations_datasource_impl.dart';
import 'package:fluffychat/data/local/localizations/language_cache_manager.dart';
import 'package:fluffychat/data/network/contact/lookup_api.dart';
import 'package:fluffychat/data/network/contact/tom_contact_api.dart';
import 'package:fluffychat/data/network/dio_cache_option.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/data/network/recovery_words/recovery_words_api.dart';
import 'package:fluffychat/data/network/search/server_search_api.dart';
import 'package:fluffychat/data/repository/contact/lookup_repository_impl.dart';
import 'package:fluffychat/data/repository/contact/phonebook_contact_repository_impl.dart';
import 'package:fluffychat/data/repository/contact/tom_contact_repository_impl.dart';
import 'package:fluffychat/data/repository/localizations/localizations_repository_impl.dart';
import 'package:fluffychat/data/repository/media/media_repository_impl.dart';
import 'package:fluffychat/data/repository/recovery_words_repository_impl.dart';
import 'package:fluffychat/data/repository/server_search_repository_impl.dart';
import 'package:fluffychat/data/repository/tom_configurations_repository_impl.dart';
import 'package:fluffychat/di/global/hive_di.dart';
import 'package:fluffychat/di/global/network_connectivity_di.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';
import 'package:fluffychat/domain/repository/localizations/localizations_repository.dart';
import 'package:fluffychat/domain/repository/lookup_repository.dart';
import 'package:fluffychat/domain/repository/phonebook_contact_repository.dart';
import 'package:fluffychat/domain/repository/recovery_words_repository.dart';
import 'package:fluffychat/domain/repository/server_search_repository.dart';
import 'package:fluffychat/domain/repository/tom_configurations_repository.dart';
import 'package:fluffychat/domain/usecase/contacts/lookup_match_contact_interactor.dart';
import 'package:fluffychat/domain/usecase/create_direct_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/download_file_for_preview_interactor.dart';
import 'package:fluffychat/domain/usecase/forward/forward_message_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/phonebook_contact_interactor.dart';
import 'package:fluffychat/domain/usecase/preview_url/get_preview_url_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/delete_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/get_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/save_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/room/chat_get_pinned_events_interactor.dart';
import 'package:fluffychat/domain/usecase/room/chat_room_search_interactor.dart';
import 'package:fluffychat/domain/usecase/room/create_new_group_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/room/timeline_search_event_interactor.dart';
import 'package:fluffychat/domain/usecase/room/upload_content_interactor.dart';
import 'package:fluffychat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:fluffychat/domain/usecase/search/pre_search_recent_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/search/server_search_interactor.dart';
import 'package:fluffychat/domain/usecase/send_file_interactor.dart';
import 'package:fluffychat/domain/usecase/send_file_on_web_interactor.dart';
import 'package:fluffychat/domain/usecase/send_images_interactor.dart';
import 'package:fluffychat/domain/usecase/send_media_on_web_with_caption_interactor.dart';
import 'package:fluffychat/domain/usecase/settings/save_language_interactor.dart';
import 'package:fluffychat/domain/usecase/settings/update_profile_interactor.dart';
import 'package:fluffychat/event/twake_event_dispatcher.dart';
import 'package:fluffychat/utils/famedlysdk_store.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class GetItInitializer {
  static final GetItInitializer _singleton = GetItInitializer._internal();

  factory GetItInitializer() {
    return _singleton;
  }

  GetItInitializer._internal();

  void setUp() {
    bindingGlobal();
    bindingQueue();
    bindingAPI();
    bindingDatasource();
    bindingDatasourceImpl();
    bindingRepositories();
    bindingInteractor();
  }

  void bindingGlobal() {
    setupDioCache();
    NetworkDI().bind();
    HiveDI().bind();
    NetworkConnectivityDI().bind();
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton(TwakeEventDispatcher());
    getIt.registerSingleton(Store());
    getIt.registerFactory<LanguageCacheManager>(() => LanguageCacheManager());
  }

  void bindingQueue() {
    getIt.registerFactory<Queue>(() => Queue());
  }

  void setupDioCache() {
    DioCacheOption.instance.setUpDioHiveCache();
  }

  void bindingAPI() {
    getIt.registerLazySingleton<RecoveryWordsAPI>(() => RecoveryWordsAPI());
    getIt.registerFactory<TomContactAPI>(() => TomContactAPI());
    getIt.registerFactory<LookupAPI>(() => LookupAPI());
    getIt.registerSingleton<MediaAPI>(MediaAPI());
    getIt.registerSingleton<ServerSearchAPI>(ServerSearchAPI());
  }

  void bindingDatasource() {
    getIt.registerFactory<ToMConfigurationsDatasource>(
      () => HiveToMConfigurationDatasource(),
    );
    getIt.registerFactory<MediaDataSource>(
      () => MediaDataSourceImpl(getIt.get<MediaAPI>()),
    );
    getIt.registerFactory<LocalizationsDataSource>(
      () => LocalizationsDataSourceImpl(
        getIt.get<LanguageCacheManager>(),
      ),
    );
    getIt.registerFactory<ServerSearchDatasource>(
      () => ServerSearchDatasourceImpl(),
    );
  }

  void bindingDatasourceImpl() {
    getIt.registerLazySingleton<RecoveryWordsDataSource>(
      () => RecoveryWordsDataSourceImpl(),
    );
    getIt.registerFactory<TomContactsDatasource>(
      () => TomContactsDatasourceImpl(),
    );
    getIt.registerFactory<LookupDatasource>(
      () => LookupDatasourceImpl(),
    );
    getIt.registerFactory<PhonebookContactDatasource>(
      () => PhonebookContactDatasourceImpl(),
    );
    getIt.registerLazySingleton(
      () => MediaDataSourceImpl(
        getIt.get<MediaAPI>(),
      ),
    );
    getIt.registerFactory(
      () => LocalizationsDataSourceImpl(
        getIt.get<LanguageCacheManager>(),
      ),
    );
  }

  void bindingRepositories() {
    getIt.registerFactory<ToMConfigurationsRepository>(
      () => ToMConfigurationsRepositoryImpl(),
    );
    getIt.registerLazySingleton<RecoveryWordsRepository>(
      () => RecoveryWordsRepositoryImpl(),
    );
    getIt.registerFactory<ContactRepository>(() => TomContactRepositoryImpl());
    getIt.registerFactory<LookupRepository>(() => LookupRepositoryImpl());
    getIt.registerFactory<PhonebookContactRepository>(
      () => PhonebookContactRepositoryImpl(),
    );
    getIt.registerFactory<MediaRepositoryImpl>(
      () => MediaRepositoryImpl(
        getIt.get<MediaDataSourceImpl>(),
      ),
    );
    getIt.registerFactory<LocalizationsRepository>(
      () => LocalizationsRepositoryImpl(
        getIt.get<LocalizationsDataSourceImpl>(),
      ),
    );
    getIt.registerFactory<ServerSearchRepository>(
      () => ServerSearchRepositoryImpl(),
    );
  }

  void bindingInteractor() {
    getIt.registerLazySingleton<GetRecoveryWordsInteractor>(
      () => GetRecoveryWordsInteractor(),
    );
    getIt.registerLazySingleton<SaveRecoveryWordsInteractor>(
      () => SaveRecoveryWordsInteractor(),
    );
    getIt.registerLazySingleton<DeleteRecoveryWordsInteractor>(
      () => DeleteRecoveryWordsInteractor(),
    );
    getIt.registerFactory<GetTomContactsInteractor>(
      () => GetTomContactsInteractor(),
    );
    getIt.registerFactory<PhonebookContactInteractor>(
      () => PhonebookContactInteractor(),
    );
    getIt.registerSingleton<SendImagesInteractor>(SendImagesInteractor());
    getIt.registerSingleton<DownloadFileForPreviewInteractor>(
      DownloadFileForPreviewInteractor(),
    );
    getIt.registerSingleton<SendFileInteractor>(SendFileInteractor());
    getIt.registerSingleton<SendFileOnWebInteractor>(SendFileOnWebInteractor());
    getIt.registerSingleton<CreateNewGroupChatInteractor>(
      CreateNewGroupChatInteractor(),
    );
    getIt.registerSingleton<UploadContentInteractor>(UploadContentInteractor());
    getIt.registerSingleton<UploadContentInBytesInteractor>(
      UploadContentInBytesInteractor(),
    );
    getIt.registerSingleton<CreateDirectChatInteractor>(
      CreateDirectChatInteractor(),
    );
    getIt.registerSingleton<ForwardMessageInteractor>(
      ForwardMessageInteractor(),
    );
    getIt.registerSingleton<PreSearchRecentContactsInteractor>(
      PreSearchRecentContactsInteractor(),
    );
    getIt.registerSingleton<SearchRecentChatInteractor>(
      SearchRecentChatInteractor(),
    );
    getIt.registerSingleton<ChatRoomSearchInteractor>(
      ChatRoomSearchInteractor(),
    );
    getIt.registerSingleton<GetPreviewURLInteractor>(
      GetPreviewURLInteractor(
        getIt.get<MediaRepositoryImpl>(),
      ),
    );
    getIt.registerSingleton<TimelineSearchEventInteractor>(
      TimelineSearchEventInteractor(),
    );
    getIt.registerSingleton<UpdateProfileInteractor>(
      UpdateProfileInteractor(),
    );
    getIt.registerFactory<ChatGetPinnedEventsInteractor>(
      () => ChatGetPinnedEventsInteractor(),
    );
    getIt.registerSingleton<ContactsManager>(ContactsManager());
    getIt.registerLazySingleton<SaveLanguageInteractor>(
      () => SaveLanguageInteractor(
        getIt.get<LocalizationsRepository>(),
      ),
    );
    getIt.registerLazySingleton<SendMediaOnWebWithCaptionInteractor>(
      () => SendMediaOnWebWithCaptionInteractor(),
    );
    getIt.registerSingleton<ServerSearchInteractor>(ServerSearchInteractor());
    getIt.registerFactory<LookupMatchContactInteractor>(
      () => LookupMatchContactInteractor(),
    );
  }
}
