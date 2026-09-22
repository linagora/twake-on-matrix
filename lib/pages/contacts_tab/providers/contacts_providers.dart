import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/contact/datasources/contact_local_datasource.dart';
import 'package:twake_chat/data/contact/datasources/matrix_room_member_datasource.dart';
import 'package:twake_chat/data/contact/datasources_impl/contact_local_datasource_impl.dart';
import 'package:twake_chat/data/contact/datasources_impl/matrix_room_member_datasource_impl.dart';
import 'package:twake_chat/data/contact/repositories/unified_contact_repository_impl.dart';
import 'package:twake_chat/data/contact/sources/matrix_room_member_source.dart';
import 'package:twake_chat/data/contact/sources/phonebook_source.dart';
import 'package:twake_chat/data/contact/sources/tom_address_book_source.dart';
import 'package:twake_chat/data/contact/sources/tom_user_info_source.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_session.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/delete_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';
import 'package:twake_chat/domain/repository/contact/address_book_repository.dart';
import 'package:twake_chat/domain/repository/phonebook_contact_repository.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'contacts_providers.g.dart';

/// Test seam: the active unified contact repository, populated when
/// [unifiedContactRepositoryProvider] builds. Integration tests use it to seed
/// contacts without reaching into the widget tree.
@visibleForTesting
UnifiedContactRepository? debugUnifiedContactRepository;

/// Pure DI: the resolution policy has no dependency and no state.
@riverpod
ContactResolutionPolicy contactResolutionPolicy(Ref ref) =>
    const ContactResolutionPolicy();

/// Single Hive-backed store for the whole session: it owns the broadcast
/// stream, so it must not be auto-disposed between screens.
@Riverpod(keepAlive: true)
ContactLocalDataSource contactLocalDataSource(Ref ref) {
  final dataSource = ContactLocalDataSourceImpl();
  ref.onDispose(dataSource.dispose);
  return dataSource;
}

@Riverpod(keepAlive: true)
UnifiedContactRepository unifiedContactRepository(Ref ref) {
  final repository = UnifiedContactRepositoryImpl(
    ref.watch(contactLocalDataSourceProvider),
  );
  debugUnifiedContactRepository = repository;
  ref.onDispose(() => debugUnifiedContactRepository = null);
  return repository;
}

/// Legacy sources still wired through get_it until they are migrated.
@riverpod
List<ContactSource> contactSources(Ref ref) => [
  TomAddressBookSource(getIt.get<AddressBookRepository>()),
  PhonebookSource(getIt.get<PhonebookContactRepository>()),
  MatrixRoomMemberSource(ref.watch(matrixRoomMemberDatasourceProvider)),
];

@riverpod
MatrixRoomMemberDatasource matrixRoomMemberDatasource(Ref ref) =>
    MatrixRoomMemberDatasourceImpl(ref.watch(activeMatrixClientProvider));

/// Second-pass enricher: canonical TOM `user_info` profile for stored contacts.
@riverpod
TomUserInfoSource tomUserInfoEnricher(Ref ref) => TomUserInfoSource(
  repository: ref.watch(unifiedContactRepositoryProvider),
  userInfoRepository: getIt.get<UserInfoRepository>(),
  policy: ref.watch(contactResolutionPolicyProvider),
);

@riverpod
SyncContactsUseCase syncContactsUseCase(Ref ref) => SyncContactsUseCase(
  repository: ref.watch(unifiedContactRepositoryProvider),
  policy: ref.watch(contactResolutionPolicyProvider),
  sources: ref.watch(contactSourcesProvider),
);

@riverpod
WatchUnifiedContactsUseCase watchUnifiedContactsUseCase(Ref ref) =>
    WatchUnifiedContactsUseCase(ref.watch(unifiedContactRepositoryProvider));

@riverpod
GetUnifiedContactUseCase getUnifiedContactUseCase(Ref ref) =>
    GetUnifiedContactUseCase(ref.watch(unifiedContactRepositoryProvider));

@riverpod
AddContactUseCase addContactUseCase(Ref ref) =>
    AddContactUseCase(ref.watch(unifiedContactRepositoryProvider));

@riverpod
DeleteContactUseCase deleteContactUseCase(Ref ref) =>
    DeleteContactUseCase(ref.watch(unifiedContactRepositoryProvider));

/// The queue outlives account-scoped services; Hive is shared across accounts.
final contactMutationQueueProvider = Provider<ContactMutationQueue>(
  (ref) => ContactMutationQueue(),
);

@Riverpod(keepAlive: true)
ContactSyncService contactSyncService(Ref ref) {
  final service = ContactSyncService(
    enabled: ref.watch(activeMatrixClientProvider) != null,
    mutations: ref.watch(contactMutationQueueProvider),
    repository: ref.watch(unifiedContactRepositoryProvider),
    policy: ref.watch(contactResolutionPolicyProvider),
    syncContacts: ref.watch(syncContactsUseCaseProvider),
    watchUnifiedContacts: ref.watch(watchUnifiedContactsUseCaseProvider),
    getUnifiedContact: ref.watch(getUnifiedContactUseCaseProvider),
    addContact: ref.watch(addContactUseCaseProvider),
    deleteContact: ref.watch(deleteContactUseCaseProvider),
    enrichers: [ref.watch(tomUserInfoEnricherProvider)],
  );
  ref.onDispose(service.dispose);
  return service;
}
