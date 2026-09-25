import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/contact/datasources/contact_local_datasource.dart';
import 'package:twake_chat/data/contact/datasources_impl/contact_local_datasource_impl.dart';
import 'package:twake_chat/data/contact/repositories/unified_contact_repository_impl.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';

part 'contacts_providers.g.dart';

// `GetTomContactsInteractor` predates the Riverpod migration and is still
// consumed by the non-Riverpod `ContactsManager`; this provider gives
// Riverpod consumers a `ref.read` path instead of reaching into GetIt.
@riverpod
GetTomContactsInteractor getTomContactsInteractor(Ref ref) =>
    getIt.get<GetTomContactsInteractor>();

/// Pure DI: the resolution policy has no dependency and no state.
///
/// It is exposed as a provider from the start so that call sites added in the
/// later PRs (store, service, controller) never instantiate it directly.
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
UnifiedContactRepository unifiedContactRepository(Ref ref) =>
    UnifiedContactRepositoryImpl(ref.watch(contactLocalDataSourceProvider));
