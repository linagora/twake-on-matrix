import 'dart:collection';

import 'package:twake_chat/config/app_grid_config/app_config_loader.dart';
import 'package:twake_chat/data/datasource/capabilities/server_capabilities_datasource.dart';
import 'package:twake_chat/data/datasource/contact/address_book_datasource.dart';
import 'package:twake_chat/data/datasource/contact/hive_third_party_contact_datasource.dart';
import 'package:twake_chat/data/datasource/contact/contacts_provider.dart';
import 'package:twake_chat/data/datasource/contact/phonebook_datasource.dart';
import 'package:twake_chat/data/datasource/contact/sim_country/sim_country_provider.dart';
import 'package:twake_chat/data/datasource/contact/sim_country/sim_country_provider_impl.dart';
import 'package:twake_chat/data/datasource/federation_configurations_datasource.dart';
import 'package:twake_chat/data/datasource/invitation/hive_invitation_status_datasource.dart';
import 'package:twake_chat/data/datasource/invitation/invitation_datasource.dart';
import 'package:twake_chat/data/datasource/localizations/localizations_datasource.dart';
import 'package:twake_chat/data/datasource/media/media_data_source.dart';
import 'package:twake_chat/data/datasource/multiple_account/multiple_account_datasource.dart';
import 'package:twake_chat/data/datasource/reactions/reactions_datasource.dart';
import 'package:twake_chat/data/datasource/recovery_words_data_source.dart';
import 'package:twake_chat/utils/logging/filters/sensitive_data_filter.dart';
import 'package:twake_chat/utils/logging/log_orchestrator.dart';
import 'package:twake_chat/data/datasource/server_config_datasource.dart';
import 'package:twake_chat/data/datasource/server_search_datasource.dart';
import 'package:twake_chat/data/datasource/tom_configurations_datasource.dart';
import 'package:twake_chat/data/datasource/tom_contacts_datasource.dart';
import 'package:twake_chat/data/datasource/user_info/user_info_datasource.dart';
import 'package:twake_chat/data/datasource_impl/capabilities/server_capabilities_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/contact/address_book_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/contact/hive_third_party_contact_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/contact/phonebook_contact_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/contact/tom_contacts_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/federation_configurations_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/invitation/hive_invitation_status_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/invitation/invitation_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/localizations/localizations_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/media/media_data_source_impl.dart';
import 'package:twake_chat/data/datasource_impl/multiple_account/multiple_account_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/reactions/reactions_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/recovery_words_data_source_impl.dart';
import 'package:twake_chat/data/datasource_impl/server_config_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/server_search_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/tom_configurations_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/user_info/user_info_datasource_impl.dart';
import 'package:twake_chat/data/local/contact/shared_preferences_contact_cache_manager.dart';
import 'package:twake_chat/data/local/localizations/language_cache_manager.dart';
import 'package:twake_chat/data/local/multiple_account/multiple_account_cache_manager.dart';
import 'package:twake_chat/data/local/reaction/reaction_cache_manager.dart';
import 'package:twake_chat/data/network/capabilities/server_capabilities_api.dart';
import 'package:twake_chat/data/network/contact/address_book_api.dart';
import 'package:twake_chat/data/network/contact/tom_contact_api.dart';
import 'package:twake_chat/data/network/dio_cache_option.dart';
import 'package:twake_chat/data/network/invitation/invitation_api.dart';
import 'package:twake_chat/data/network/media/media_api.dart';
import 'package:twake_chat/data/network/recovery_words/recovery_words_api.dart';
import 'package:twake_chat/data/network/search/server_search_api.dart';
import 'package:twake_chat/data/network/server_config_api.dart';
import 'package:twake_chat/data/network/user_info/user_info_api.dart';
import 'package:twake_chat/data/repository/capabilities/server_capabilities_repository_impl.dart';
import 'package:twake_chat/data/repository/contact/address_book_repository_impl.dart';
import 'package:twake_chat/data/repository/contact/hive_third_party_contact_repository_impl.dart';
import 'package:twake_chat/data/repository/contact/phonebook_contact_repository_impl.dart';
import 'package:twake_chat/data/repository/contact/tom_contact_repository_impl.dart';
import 'package:twake_chat/data/repository/federation_configurations_repository_impl.dart';
import 'package:twake_chat/data/repository/invitation/hive_invitation_status_repository_impl.dart';
import 'package:twake_chat/data/repository/invitation/invitation_repository_impl.dart';
import 'package:twake_chat/data/repository/localizations/localizations_repository_impl.dart';
import 'package:twake_chat/data/repository/media/media_repository_impl.dart';
import 'package:twake_chat/data/repository/multiple_account/multiple_account_repository_impl.dart';
import 'package:twake_chat/data/repository/reactions/reactions_repository_impl.dart';
import 'package:twake_chat/data/repository/recovery_words_repository_impl.dart';
import 'package:twake_chat/data/repository/server_config_repository_impl.dart';
import 'package:twake_chat/data/repository/server_search_repository_impl.dart';
import 'package:twake_chat/data/repository/tom_configurations_repository_impl.dart';
import 'package:twake_chat/data/repository/user_info_repository_impl.dart';
import 'package:twake_chat/di/global/hive_di.dart';
import 'package:twake_chat/di/global/network_connectivity_di.dart';
import 'package:twake_chat/di/global/network_di.dart';
import 'package:twake_chat/domain/contact_manager/contacts_manager.dart';
import 'package:twake_chat/domain/repository/capabilities/server_capabilities_repository.dart';
import 'package:twake_chat/domain/repository/contact/address_book_repository.dart';
import 'package:twake_chat/domain/repository/contact/hive_contact_repository.dart';
import 'package:twake_chat/domain/repository/contact_repository.dart';
import 'package:twake_chat/domain/repository/federation_configurations_repository.dart';
import 'package:twake_chat/domain/repository/invitation/hive_invitation_status_repository.dart';
import 'package:twake_chat/domain/repository/invitation/invitation_repository.dart';
import 'package:twake_chat/domain/repository/localizations/localizations_repository.dart';
import 'package:twake_chat/domain/repository/multiple_account/multiple_account_repository.dart';
import 'package:twake_chat/domain/repository/phonebook_contact_repository.dart';
import 'package:twake_chat/domain/repository/reactions/reactions_repository.dart';
import 'package:twake_chat/domain/repository/recovery_words_repository.dart';
import 'package:twake_chat/domain/repository/server_config_repository.dart';
import 'package:twake_chat/domain/repository/server_search_repository.dart';
import 'package:twake_chat/domain/repository/tom_configurations_repository.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';
import 'package:twake_chat/domain/usecase/app_grid/get_app_grid_configuration_interactor.dart';
import 'package:twake_chat/domain/usecase/bootstrap/read_cached_recovery_key_interactor.dart';
import 'package:twake_chat/domain/usecase/bootstrap/start_self_verification_interactor.dart';
import 'package:twake_chat/domain/usecase/bootstrap/store_recovery_key_interactor.dart';
import 'package:twake_chat/domain/usecase/bootstrap/unlock_ssss_with_recovery_key_interactor.dart';
import 'package:twake_chat/domain/usecase/capabilities/get_server_capabilities_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/delete_third_party_contact_box_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/federation_look_up_phonebook_contact_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/lookup_match_contact_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/try_get_synced_phone_book_contact_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/twake_look_up_phonebook_contact_interactor.dart';
import 'package:twake_chat/domain/usecase/create_direct_chat_interactor.dart';
import 'package:twake_chat/domain/usecase/device_settings/get_devices_interactor.dart';
import 'package:twake_chat/domain/usecase/download_file_for_preview_interactor.dart';
import 'package:twake_chat/domain/usecase/forward/forward_message_interactor.dart';
import 'package:twake_chat/domain/usecase/generate_thumbnails_media_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/generate_invitation_link_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/get_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/hive_delete_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/hive_get_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/send_invitation_interactor.dart';
import 'package:twake_chat/domain/usecase/invitation/store_invitation_status_interactor.dart';
import 'package:twake_chat/domain/usecase/preview_url/get_preview_url_interactor.dart';
import 'package:twake_chat/domain/usecase/reactions/get_recent_reactions_interactor.dart';
import 'package:twake_chat/domain/usecase/reactions/store_recent_reactions_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/delete_recovery_words_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/get_recovery_words_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/save_recovery_words_interactor.dart';
import 'package:twake_chat/domain/usecase/room/ban_user_interactor.dart';
import 'package:twake_chat/domain/usecase/room/block_user_interactor.dart';
import 'package:twake_chat/domain/usecase/room/chat_get_pinned_events_interactor.dart';
import 'package:twake_chat/domain/usecase/room/chat_room_search_interactor.dart';
import 'package:twake_chat/domain/usecase/room/create_new_group_chat_interactor.dart';
import 'package:twake_chat/domain/usecase/room/create_support_chat_interactor.dart';
import 'package:twake_chat/domain/usecase/room/delete_event_interactor.dart';
import 'package:twake_chat/domain/usecase/room/download_media_file_interactor.dart';
import 'package:twake_chat/domain/usecase/room/invite_user_interactor.dart';
import 'package:twake_chat/domain/usecase/room/report_content_interactor.dart';
import 'package:twake_chat/domain/usecase/room/set_permission_level_interactor.dart';
import 'package:twake_chat/domain/usecase/room/timeline_search_event_interactor.dart';
import 'package:twake_chat/domain/usecase/room/unban_and_invite_users_interactor.dart';
import 'package:twake_chat/domain/usecase/room/unban_user_interactor.dart';
import 'package:twake_chat/domain/usecase/room/unban_users_interactor.dart';
import 'package:twake_chat/domain/usecase/room/unblock_user_interactor.dart';
import 'package:twake_chat/domain/usecase/room/update_group_chat_interactor.dart';
import 'package:twake_chat/domain/usecase/room/update_pinned_messages_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_interactor.dart';
import 'package:twake_chat/domain/usecase/search/pre_search_recent_contacts_interactor.dart';
import 'package:twake_chat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:twake_chat/domain/usecase/search/server_search_interactor.dart';
import 'package:twake_chat/domain/usecase/settings/save_language_interactor.dart';
import 'package:twake_chat/domain/usecase/settings/update_profile_interactor.dart';
import 'package:twake_chat/domain/usecase/user_info/get_user_info_interactor.dart';
import 'package:twake_chat/domain/usecase/user_info/get_user_info_visibility_interactor.dart';
import 'package:twake_chat/domain/usecase/user_info/update_user_info_visibility_interactor.dart';
import 'package:twake_chat/domain/usecase/verify_name_interactor.dart';
import 'package:twake_chat/event/twake_event_dispatcher.dart';
import 'package:twake_chat/modules/federation_identity_lookup/manager/federation_identity_lookup_manager.dart';
import 'package:twake_chat/modules/federation_identity_lookup/manager/identity_lookup_manager.dart';
import 'package:twake_chat/modules/federation_identity_request_token/manager/federation_identity_request_token_manager.dart';
import 'package:twake_chat/pages/chat/chat_pinned_events/pinned_events_controller.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_data_and_storage/isolate_storage_scanner_service.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_data_and_storage/settings_data_and_storage_scanner_service.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';
import 'package:twake_chat/utils/logging/loggers/console_logger.dart';
import 'package:twake_chat/utils/logging/loggers/sentry_logger.dart';
import 'package:twake_chat/utils/manager/download_manager/download_manager.dart';
import 'package:twake_chat/utils/manager/download_manager/downloading_worker_queue.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_worker_queue.dart';
import 'package:twake_chat/utils/power_level_manager.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';

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
    bindingManager();
    bindingDatasource();
    bindingDatasourceImpl();
    bindingRepositories();
    bindingInteractor();
    _bindingControllers();
    Logs().d('GetItInitializer::setUp(): Setup successfully');
  }

  void bindingGlobal() {
    // Initialize Logging
    final logOrchestrator = LogOrchestrator();
    logOrchestrator.addLogger(ConsoleLogger());
    logOrchestrator.addFilter(SensitiveDataFilter());
    logOrchestrator.addLogger(SentryLogger());
    getIt.registerSingleton<LogOrchestrator>(logOrchestrator);

    HiveDI().bind();
    setupDioCache();
    NetworkDI().bind();
    NetworkConnectivityDI().bind();
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton(const SearchEngine());
    getIt.registerSingleton(TwakeEventDispatcher());
    getIt.registerLazySingleton<StorageScannerService>(
      () => const IsolateStorageScannerService(),
    );
    getIt.registerSingleton(Store());
    getIt.registerFactory<AppConfigLoader>(() => AppConfigLoader());
    bindingCachingManager();
    _bindingManagers();
  }

  void bindingCachingManager() {
    getIt.registerSingleton(PowerLevelManager());
    getIt.registerFactory<MultipleAccountCacheManager>(
      () => MultipleAccountCacheManager(),
    );
    getIt.registerFactory<LanguageCacheManager>(() => LanguageCacheManager());
    getIt.registerFactory<ReactionsCacheManager>(() => ReactionsCacheManager());
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
    getIt.registerSingleton<MediaAPI>(MediaAPI());
    getIt.registerSingleton<ServerSearchAPI>(ServerSearchAPI());
    getIt.registerSingleton<ServerConfigAPI>(ServerConfigAPI());
    getIt.registerFactory<InvitationAPI>(() => InvitationAPI());
    getIt.registerSingleton(const ServerCapabilitiesAPI());
    getIt.registerSingleton(const UserInfoApi());
  }

  void bindingManager() {
    getIt.registerSingleton<DownloadWorkerQueue>(DownloadWorkerQueue());
    getIt.registerSingleton<DownloadManager>(DownloadManager());
    getIt.registerSingleton<UploadWorkerQueue>(UploadWorkerQueue());
    getIt.registerSingleton<UploadManager>(UploadManager());
  }

  void bindingDatasource() {
    getIt.registerFactory<ToMConfigurationsDatasource>(
      () => HiveToMConfigurationDatasource(),
    );
    getIt.registerFactory<FederationConfigurationsDatasource>(
      () => HiveFederationConfigurationsDatasourceImpl(),
    );
    getIt.registerFactory<HiveThirdPartyContactDatasource>(
      () => HiveThirdPartyContactDatasourceImpl(),
    );
    getIt.registerFactory<MediaDataSource>(
      () => MediaDataSourceImpl(getIt.get<MediaAPI>()),
    );
    getIt.registerFactory<LocalizationsDataSource>(
      () => LocalizationsDataSourceImpl(getIt.get<LanguageCacheManager>()),
    );
    getIt.registerFactory<ServerSearchDatasource>(
      () => ServerSearchDatasourceImpl(),
    );
    getIt.registerFactory<ServerConfigDatasource>(
      () => ServerConfigDatasourceImpl(),
    );
    getIt.registerFactory<MultipleAccountDatasource>(
      () => MultipleAccountDatasourceImpl(),
    );
    getIt.registerFactory<HiveInvitationStatusDatasource>(
      () => HiveInvitationStatusDatasourceImpl(),
    );
    getIt.registerFactory<ServerCapabilitiesDatasource>(
      () => const ServerCapabilitiesDatasourceImpl(),
    );
    getIt.registerFactory<UserInfoDatasource>(
      () => const UserInfoDatasourceImpl(),
    );
  }

  void bindingDatasourceImpl() {
    getIt.registerLazySingleton<RecoveryWordsDataSource>(
      () => RecoveryWordsDataSourceImpl(),
    );
    getIt.registerFactory<TomContactsDatasource>(
      () => TomContactsDatasourceImpl(),
    );
    getIt.registerFactory<ContactsProvider>(
      () => FlutterContactsProviderImpl(),
    );
    getIt.registerLazySingleton<SimCountryProvider>(
      () => SimCountryProviderImpl(),
    );
    getIt.registerFactory<PhonebookContactDatasource>(
      () => PhonebookContactDatasourceImpl(
        getIt.get<ContactsProvider>(),
        getIt.get<SimCountryProvider>(),
      ),
    );
    getIt.registerLazySingleton(
      () => MediaDataSourceImpl(getIt.get<MediaAPI>()),
    );
    getIt.registerFactory(
      () => LocalizationsDataSourceImpl(getIt.get<LanguageCacheManager>()),
    );

    getIt.registerFactory<ServerSearchDatasourceImpl>(
      () => ServerSearchDatasourceImpl(),
    );
    getIt.registerFactory<AddressBookDatasource>(
      () => AddressBookDatasourceImpl(),
    );
    getIt.registerFactory<InvitationDatasource>(
      () => InvitationDatasourceImpl(),
    );
    getIt.registerFactory<ReactionsDatasource>(() => ReactionsDatasourceImpl());
  }

  void bindingRepositories() {
    getIt.registerFactory<ToMConfigurationsRepository>(
      () => ToMConfigurationsRepositoryImpl(),
    );
    getIt.registerFactory<FederationConfigurationsRepository>(
      () => FederationConfigurationsRepositoryImpl(),
    );
    getIt.registerFactory<HiveContactRepository>(
      () => HiveThirdPartyContactRepositoryImpl(),
    );
    getIt.registerLazySingleton<RecoveryWordsRepository>(
      () => RecoveryWordsRepositoryImpl(),
    );
    getIt.registerFactory<ContactRepository>(() => TomContactRepositoryImpl());
    getIt.registerFactory<PhonebookContactRepository>(
      () => PhonebookContactRepositoryImpl(),
    );
    getIt.registerFactory<MediaRepositoryImpl>(
      () => MediaRepositoryImpl(getIt.get<MediaDataSourceImpl>()),
    );
    getIt.registerFactory<LocalizationsRepository>(
      () =>
          LocalizationsRepositoryImpl(getIt.get<LocalizationsDataSourceImpl>()),
    );
    getIt.registerFactory<ServerSearchRepository>(
      () => ServerSearchRepositoryImpl(),
    );
    getIt.registerFactory<MultipleAccountRepository>(
      () => MultipleAccountRepositoryImpl(),
    );
    getIt.registerFactory<ServerConfigRepository>(
      () => ServerConfigRepositoryImpl(),
    );
    getIt.registerFactory<AddressBookRepository>(
      () => AddressBookRepositoryImpl(),
    );
    getIt.registerFactory<InvitationRepository>(
      () => InvitationRepositoryImpl(),
    );
    getIt.registerFactory<HiveInvitationStatusRepository>(
      () => HiveInvitationStatusRepositoryImpl(),
    );
    getIt.registerFactory<ReactionsRepository>(() => ReactionsRepositoryImpl());
    getIt.registerFactory<ServerCapabilitiesRepository>(
      () => const ServerCapabilitiesRepositoryImpl(),
    );
    getIt.registerFactory<UserInfoRepository>(
      () => const UserInfoRepositoryImpl(),
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
    getIt.registerFactory<PostAddressBookInteractor>(
      () => PostAddressBookInteractor(),
    );
    getIt.registerFactory<FederationLookUpPhonebookContactInteractor>(
      () => FederationLookUpPhonebookContactInteractor(),
    );
    getIt.registerFactory<TwakeLookupPhonebookContactInteractor>(
      () => TwakeLookupPhonebookContactInteractor(),
    );
    getIt.registerSingleton<TryGetSyncedPhoneBookContactInteractor>(
      TryGetSyncedPhoneBookContactInteractor(),
    );
    getIt.registerSingleton<DownloadFileForPreviewInteractor>(
      DownloadFileForPreviewInteractor(),
    );
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
    getIt.registerFactory<GetDevicesInteractor>(() => GetDevicesInteractor());
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
      GetPreviewURLInteractor(getIt.get<MediaRepositoryImpl>()),
    );
    getIt.registerSingleton<TimelineSearchEventInteractor>(
      TimelineSearchEventInteractor(),
    );
    getIt.registerSingleton<UpdateProfileInteractor>(UpdateProfileInteractor());
    getIt.registerFactory<ChatGetPinnedEventsInteractor>(
      () => ChatGetPinnedEventsInteractor(),
    );
    getIt.registerSingleton<ContactsManager>(ContactsManager());
    getIt.registerLazySingleton<SaveLanguageInteractor>(
      () => SaveLanguageInteractor(getIt.get<LocalizationsRepository>()),
    );
    getIt.registerSingleton<ServerSearchInteractor>(ServerSearchInteractor());
    getIt.registerFactory<LookupMatchContactInteractor>(
      () => LookupMatchContactInteractor(),
    );
    getIt.registerSingleton<UpdateGroupChatInteractor>(
      UpdateGroupChatInteractor(),
    );
    getIt.registerLazySingleton<UpdatePinnedMessagesInteractor>(
      () => UpdatePinnedMessagesInteractor(),
    );

    getIt.registerFactory<GenerateThumbnailsMediaInteractor>(
      () => GenerateThumbnailsMediaInteractor(),
    );

    getIt.registerFactory<GetAppGridConfigurationInteractor>(
      () => GetAppGridConfigurationInteractor(getIt.get<AppConfigLoader>()),
    );

    getIt.registerSingleton<DownloadMediaFileInteractor>(
      DownloadMediaFileInteractor(),
    );

    getIt.registerFactory<VerifyNameInteractor>(() => VerifyNameInteractor());

    getIt.registerFactory<SendInvitationInteractor>(
      () => SendInvitationInteractor(),
    );

    getIt.registerFactory<GenerateInvitationLinkInteractor>(
      () => GenerateInvitationLinkInteractor(),
    );

    getIt.registerFactory<GetInvitationStatusInteractor>(
      () => GetInvitationStatusInteractor(),
    );

    getIt.registerFactory<StoreInvitationStatusInteractor>(
      () => StoreInvitationStatusInteractor(),
    );

    getIt.registerFactory<HiveGetInvitationStatusInteractor>(
      () => HiveGetInvitationStatusInteractor(),
    );

    getIt.registerFactory<HiveDeleteInvitationStatusInteractor>(
      () => HiveDeleteInvitationStatusInteractor(),
    );

    getIt.registerFactory<UnlockSsssWithRecoveryKeyInteractor>(
      () => UnlockSsssWithRecoveryKeyInteractor(),
    );

    getIt.registerFactory<ReadCachedRecoveryKeyInteractor>(
      () => ReadCachedRecoveryKeyInteractor(),
    );

    getIt.registerFactory<StoreRecoveryKeyInteractor>(
      () => StoreRecoveryKeyInteractor(),
    );

    getIt.registerFactory<StartSelfVerificationInteractor>(
      () => StartSelfVerificationInteractor(),
    );

    getIt.registerFactory<DeleteThirdPartyContactBoxInteractor>(
      () => DeleteThirdPartyContactBoxInteractor(),
    );

    getIt.registerFactory<StoreRecentReactionsInteractor>(
      () => StoreRecentReactionsInteractor(),
    );

    getIt.registerFactory<GetRecentReactionsInteractor>(
      () => GetRecentReactionsInteractor(),
    );

    getIt.registerFactory<DeleteEventInteractor>(() => DeleteEventInteractor());

    getIt.registerFactory<SetPermissionLevelInteractor>(
      () => SetPermissionLevelInteractor(),
    );

    getIt.registerFactory<BanUserInteractor>(() => BanUserInteractor());

    getIt.registerFactory<UnbanUserInteractor>(() => UnbanUserInteractor());

    getIt.registerFactory<UnblockUserInteractor>(() => UnblockUserInteractor());

    getIt.registerFactory<BlockUserInteractor>(() => BlockUserInteractor());

    getIt.registerFactory<ReportContentInteractor>(
      () => ReportContentInteractor(),
    );

    getIt.registerFactory(() => const GetServerCapabilitiesInteractor());
    getIt.registerFactory(() => const GetUserInfoInteractor());

    getIt.registerFactory(() => InviteUserInteractor());

    getIt.registerFactory(() => const GetUserInfoVisibilityInteractor());

    getIt.registerFactory(() => const UpdateUserInfoVisibilityInteractor());

    getIt.registerFactory(() => const CreateSupportChatInteractor());

    getIt.registerFactory(
      () => UnbanUsersInteractor(
        unbanUserInteractor: getIt.get<UnbanUserInteractor>(),
      ),
    );
    getIt.registerFactory(
      () => UnbanAndInviteUsersInteractor(
        inviteUserInteractor: getIt.get<InviteUserInteractor>(),
        unbanUsersInteractor: getIt.get<UnbanUsersInteractor>(),
      ),
    );
  }

  void _bindingControllers() {
    getIt.registerFactory<PinnedEventsController>(
      () => PinnedEventsController(),
    );
  }

  void _bindingManagers() {
    getIt.registerFactory<IdentityLookupManager>(() => IdentityLookupManager());
    getIt.registerFactory<FederationIdentityRequestTokenManager>(
      () => FederationIdentityRequestTokenManager(),
    );
    getIt.registerFactory<AddressBookApi>(() => AddressBookApi());
    getIt.registerFactory<FederationIdentityLookupManager>(
      () => FederationIdentityLookupManager(),
    );
    getIt.registerFactory<SharedPreferencesContactCacheManager>(
      () => SharedPreferencesContactCacheManager(),
    );
  }
}
