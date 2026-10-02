import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';

/// Builds a [ContactSyncService] over [repository] with the real use cases,
/// so tests only fake the leaves (store, sources, enrichers, resolver).
ContactSyncService buildContactSyncService({
  required String userId,
  required UnifiedContactRepository repository,
  List<ContactSource> sources = const <ContactSource>[],
  ContactSyncOptions options = const ContactSyncOptions(),
}) {
  const policy = ContactResolutionPolicy();
  return ContactSyncService(
    userId: userId,
    repository: repository,
    policy: policy,
    useCases: ContactUseCases(
      sync: SyncContactsUseCase(
        repository: repository,
        policy: policy,
        sources: sources,
      ),
      watch: WatchUnifiedContactsUseCase(repository),
      get: GetUnifiedContactUseCase(repository),
      add: AddContactUseCase(repository),
    ),
    options: options,
  );
}
